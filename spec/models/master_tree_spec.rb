require 'spec_helper'

describe MasterTree do

  before(:all) do
    @master_tree = Factory(:master_tree, :abstract => "It is my tree of very strange taxa")
    @root = Factory(:node, :tree => @master_tree)
    5.times { Factory(:node, :parent => @root, :tree => @master_tree) }
    @master_tree.children_of(@root).each do |child|
      5.times { Factory(:node, :parent => child, :tree => @master_tree) }
      5.times { Factory(:vernacular_name, :node => child) }
      5.times { Factory(:synonym, :node => child) }
    end
  end

  it { should be_kind_of(Tree) }
  it { should have_many(:reference_tree_collections) }
  it { should have_many(:reference_trees).through(:reference_tree_collections) }

  it "should get deleted tree upon creation" do
    tree = Factory(:master_tree)
    deleted_names = DeletedTree.where(:master_tree_id => tree.id)
    deleted_names.size.should == 1
    deleted_names[0].title.should == "Deleted Names"
  end

  describe "#create_darwin_core_archive" do

    before(:all) do
      MasterTreeContributor.create!(:master_tree => @master_tree, :user => Factory(:user))
      @dwc_file = File.join(::Rails.root.to_s, 'tmp', "#{@master_tree.uuid}.tar.gz")
      FileUtils.rm(@dwc_file) if File.exists?(@dwc_file)
      File.exists?(@dwc_file).should be_false
      @root_nodes = @master_tree.root.children
      @master_tree.create_darwin_core_archive
      @dwca = DarwinCore.new(@dwc_file)
      @parent_index = @dwca.core.fields.select { |f| f[:term] == 'http://rs.tdwg.org/dwc/terms/parentNameUsageID' }[0][:index]
      @dwca_nodes = @dwca.core.read[0]
      @dwca_nodes = @dwca_nodes.inject({}) { |res, n| res[n[@dwca.core.id[:index]]] = n[@parent_index]; res }
      vernacular_extension = @dwca.extensions.select {|e| !!(e.fields.select {|f| f[:type] == "http://rs.tdwg.org/dwc/terms/vernacularName" }.empty?) }
      @vernacular_extension = vernacular_extension.empty? ? nil : vernacular_extension[0]
      synonym_extension = @dwca.extensions.select {|e| !!(e.fields.select {|f| f[:type] == "http://rs.tdwg.org/dwc/terms/scientificName" }.empty?) }
      @synonym_extension = synonym_extension.empty? ? nil : synonym_extension[0]

    end

    it "should have publish method" do
      @master_tree.respond_to?(:create_darwin_core_archive).should be_true
    end

    it "should create a valid dwc_archive in tmp directory" do
      File.exists?(@dwc_file).should be_true
      @dwca.archive.valid?.should be_true
    end

    it "should read eml metadata of the archive" do
      @dwca.metadata.authors.size.should == 2
    end

    it "should not have master tree's hidden root in core file" do
      @dwca_nodes.key?(@master_tree.root.id.to_s).should be_false
    end

    it "roots of the core file should have null as parent id" do
      @root_nodes.each do |root_node|
        root_id = root_node.id.to_s
        @dwca_nodes.key?(root_id).should be_true
        @dwca_nodes[root_id].to_i.should_not == root_node.parent_id
        @dwca_nodes[root_id].should be_nil
      end
    end

    it "should have extension with vernacular names" do
      @vernacular_extension.should_not be_nil
    end

    it "should have vernacular names for a root child" do
      child_id = @master_tree.root.children.first.children.first.id
      @vernacular_extension.read[0].select { |r| r[@vernacular_extension.id[:index]].to_i == child_id }.size.should > 1
    end

    it "should have extension with synonyms" do
      @synonym_extension.should_not be_nil
    end

    it "should have synonyms for a root child" do
      child_id = @master_tree.root.children.first.children.first.id
      @synonym_extension.read[0].select { |r| r[@synonym_extension.id[:index]].to_i == child_id }.size.should > 1
    end

  end

end

describe MasterTree, 'finding in sorted by title' do
  let(:user) { Factory(:email_confirmed_user) }
  let(:z_tree) { Factory(:master_tree, :title => 'z', :user => user) }
  let(:b_tree) { Factory(:master_tree, :title => 'b', :user => user) }
  let(:a_tree) { Factory(:master_tree, :title => 'a', :user => user) }

  it 'finds the trees in ascending title order' do
    user.master_trees.by_title.should == [a_tree, b_tree, z_tree]
  end
end



