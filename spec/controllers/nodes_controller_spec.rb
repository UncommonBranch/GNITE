require 'spec_helper'

describe NodesController, 'when signed out on POST to create' do
  before do
    post :create, :master_tree_id => 123, :node_id => 456
  end
  subject { controller }
  it { should redirect_to(new_user_session_url) }
  it { should set_the_flash.to(/sign in/) }
end

describe NodesController do
  context "signed in with a tree and nodes" do
    let(:user)        { Factory(:user) }

    before do
      sign_in user
    end

    context "when signed in with a tree" do
      let(:user) { Factory(:user) }
      let(:tree) { Factory(:master_tree, :user_id => user.id, :user => user) }
      let(:node) do 
        node = Factory(:node, :tree => tree)
        Factory(:node, :tree => tree, :parent => node)
        node
      end
      let(:nodes) { tree.nodes }
      
      subject { controller }

      before do
        sign_in user
      end

      context "on GET to #index without a parent_id" do
        before do
          get :index, :master_tree_id => tree.id, :format => 'html'
        end

        it { should respond_with(:success) }
        it { should render_template(:node) }
      end
      
      context "on GET to #index with a parent_id" do
        before do
          get :index, :master_tree_id => tree.id, :parent_id => node.id, :format => 'html'
        end

        it { should respond_with(:success) }
        it { should render_template(:node) }
      end

    end
  end
end

describe NodesController, 'POST to create a node' do
  subject { controller }
  let(:user) { Factory(:user) }
  let(:tree) do
    tree = Factory(:master_tree, :user_id => user.id)
    Factory(:node, :tree => tree)
    tree
  end
  let(:nodes) { tree.nodes }
  let(:node_attributes) do
    name = Factory(:name, :name_string => "My new node")
    { :tree => tree, :name => name }
  end
  let(:new_node) { Factory.build(:node, node_attributes) }

  before do
    sign_in user
    controller.stubs(:current_user => user)
    user_trees = [tree]
    user.stubs(:master_trees => user_trees)
    user_trees.stubs(:find => tree)
    tree.stubs(:children_of => nodes)
    ::Node.stubs(:new => new_node)
    new_node.stubs(:save => true)
    @node_count = ::Node.count
    r = Resque::Worker.new(Gnite::Config.action_queue)
    post :create, :master_tree_id => tree.id, :format => 'json', :new_node => { :name => { :name_string => node_attributes[:name].name_string } }, :action_type => 'ActionAddNode'
  end

  it 'creates a new node' do
    (::Node.count - @node_count).should == 1
  end

  it { should respond_with(:success) }

  it 'renders the newly created node as JSON' do
    node = JSON.parse(response.body, :symbolize_names => true)
    node.keys.should == [:node]
  end
end


describe NodesController, 'POST to copy a node from a reference tree' do
  let(:user) { Factory(:user) }
  let(:master_tree) { Factory(:master_tree, :user_id => user.id) }
  let(:parent_node) { Factory(:node, :tree => master_tree) }
  let(:reference_node) do
    child_name = Factory(:name, :name_string => 'child name')
    grandchild_name = Factory(:name, :name_string => 'grandchild_name')
    node = Factory(:node, :tree => Factory(:reference_tree))
    child = Factory(:node, :tree => node.tree, :parent => node, :name => child_name)
    grandchild = Factory(:node, :tree => node.tree, :parent => child, :name => grandchild_name)
    node
  end
  subject { controller }

  before do
    sign_in user
    @node_count = parent_node.children.size
    r = Resque::Worker.new(Gnite::Config.action_queue)
    post :create,
      :master_tree_id => master_tree.id,
      :format => 'json',
      :new_node => {
        :id => reference_node.id,
        :parent_id => parent_node.id
      },
      :action_type => 'ActionCopyNodeFromAnotherTree'
    @clone_node = ::Node.find(JSON.parse(response.body)['node']['id'])
  end

  it { should respond_with(:success) }

  it 'creates a new node' do
    (parent_node.children.size - @node_count).should == 1
  end

  it 'renders the newly created node as JSON' do
    @clone_node.is_a?(::Node).should be_true
  end

  it 'should create a copy of the reference tree node' do
    @clone_node.name_id.should == reference_node.name_id
    @clone_node.children[0].name_id.should == reference_node.children[0].name_id
    @clone_node.children[0].children[0].name_id.should == reference_node.children[0].children[0].name_id
  end

end

describe NodesController, 'POST to assign a node to be a synonym of another' do
  let(:user) { Factory(:user) }
  let(:master_tree) { Factory(:master_tree, :user_id => user.id) }
  let(:source_node) { Factory(:node, :tree => master_tree, :name => Factory(:name, :name_string => "source node")) }
  let(:source_synonym) { Factory(:synonym, :node => source_node) }
  let(:source_vernacular) { Factory(:vernacular_name, :node => source_node) }
  let(:destination_node) do
    parent = Factory(:node, :tree => master_tree, :name => Factory(:name, :name_string => "destination node"))
    Factory(:node, :parent => parent, :tree => master_tree, :name => Factory(:name, :name_string => "destination child"))
    parent
  end
  subject { controller }
  
  before do
    sign_in user
    @child_count = master_tree.root.children.size
    r = Resque::Worker.new(Gnite::Config.action_queue)
    post :create,
      :master_tree_id => master_tree.id,
      :format => 'json',
      :new_node => { 
        :id => source_node.id,
        :destination_node_id => destination_node.id
      },
      :action_type => 'ActionNodeToSynonym'
    @merge_node = ::Node.find(JSON.parse(response.body)['undo']['merged_node_id'])
  end
  
  it { should respond_with(:success) }
  
  it 'renders the newly merged node as JSON' do
    @merge_node.is_a?(::Node).should be_true
  end
  
  it 'destroys the source node' do
    (master_tree.root.children.size - @child_count).should == 1
    master_tree.root.children.map(&:name).include?(destination_node.name_string).should be_true
    master_tree.root.children.map(&:name).include?(source_node.name_string).should be_false
  end
  
  it 'should render the merged node with same name as destination node' do
    @merge_node.name_id.should == destination_node.name_id
    @merge_node.name == destination_node.name
  end
  
  it 'should render the merged node with synonym containing source node and source synonym' do
    @merge_node.synonyms.map(&:name).include?(source_node.name_string).should be_true
    @merge_node.synonyms.map(&:name).include?(source_syonym.name_string).should be_true
  end
  
  it 'should render the merged node with same number of children' do
    @merge_node.children.size.should == destination_node.children.size
  end
  
end


describe NodesController, 'PUT to update' do
  let(:user) { Factory(:user) }
  let(:tree) { Factory(:master_tree, :user_id => user.id) }
  let(:node)  { Factory(:node, :tree => tree) }
  subject { controller }

  before do
    sign_in user
    r = Resque::Worker.new(Gnite::Config.action_queue)
    put :update,
      :id => node.id,
      :master_tree_id => tree.id,
      :format => 'json',
      :node => (node_attributes rescue nil),
      :action_type => (action_type rescue nil)
  end

  context 'when moving node within tree' do
    let(:new_parent_node) { Factory(:node, :tree => tree) }
    let(:node_attributes) { { :parent_id => new_parent_node.id } }
    let(:action_type) { "ActionMoveNodeWithinTree" }

    it { should respond_with(:success) }

    it "should update the node's parent" do
      node.reload.parent.should == new_parent_node
    end

    it "should render the updated node as JSON" do
      response.body.should == node.reload.to_json
    end
  end

  context "when deleting a node" do
    let(:node_attributes) { { :parent_id => node.parent.id } }
    let(:action_type) { "ActionMoveNodeToDeletedTree" }

    it { should respond_with(:success) }

    it "should move node to deleted tree" do
      node_parent_tree = node.reload.parent.tree
      node_parent_tree.class.should == DeletedTree
      node.parent.should == node_parent_tree.root
    end
  end

  context "when renaming a node" do
    let(:node_attributes) { { :name => { :name_string => 'Updated name' } } }
    let(:action_type) { "ActionRenameNode" }

    it { should respond_with(:success) }

    it "should rename node" do
      node.reload.name.should == Name.find_by_name_string('Updated name')
    end
  end

end

describe NodesController, 'GET to show for master tree' do
  let(:user) { Factory(:user) }
  let(:tree) { Factory(:master_tree, :user => user) }
  let(:node) { Factory(:node, :tree => tree) }
  let(:synonym) { Factory(:synonym, :node => node, :name => Factory(:name, :name_string => 'Point'), :status => 'synonym') }
  let(:language) { Factory(:language, :name => 'English', :iso_639_1 => 'en', :iso_639_2 => 'eng', :iso_639_3 => 'eng', :native => 'English') }
  let(:vernacular) { Factory(:vernacular_name, :node => node, :name => Factory(:name, :name_string => 'Coordinate'), :language => language) }

  subject { controller }

  before do
    sign_in user

    @expected = {
      :id          => node.id,
      :name        => node.name_string,
      :rank        => node.rank,
      :synonyms    => node.synonym_data,
      :vernaculars => node.vernacular_data
    }

    get :show, :id => node.id, :master_tree_id => tree.id, :format => 'json'
  end

  it { should respond_with(:success) }

  it 'should render synonyms, vernacular names, and rank as JSON' do
    response.body.should == @expected.to_json
  end
end

describe NodesController, 'GET to show for reference tree' do
  let(:user) { Factory(:user) }
  let(:tree) { Factory(:reference_tree) }
  let(:node) { Factory(:node, :tree => tree) }
  let(:synonym) { Factory(:synonym, :node => node, :name => Factory(:name, :name_string => 'Point'), :status => 'synonym') }
  let(:language) { Factory(:language, :name => 'English', :iso_639_1 => 'en', :iso_639_2 => 'eng', :iso_639_3 => 'eng', :native => 'English') }
  let(:vernacular) { Factory(:vernacular_name, :node => node, :name => Factory(:name, :name_string => 'Coordinate'), :language => language) }

  subject { controller }

  before do
    sign_in user

    @expected = {
      :id          => node.id,
      :name        => node.name_string,
      :rank        => node.rank,
      :synonyms    => node.synonym_data,
      :vernaculars => node.vernacular_data
    }

    get :show, :id => node.id, :reference_tree_id => tree.id, :format => 'json'
  end

  it { should respond_with(:success) }

  it 'should render synonyms, vernacular names, and rank as JSON' do
    response.body.should == @expected.to_json
  end
end
