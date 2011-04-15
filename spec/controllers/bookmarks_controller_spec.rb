require 'spec_helper'

describe BookmarksController, 'GET to show bookmarks for master tree' do
  let(:user) { Factory(:email_confirmed_user) }
  let(:master_tree) { Factory(:master_tree, :user => user) }
  let(:node)  { Factory(:node, :tree => master_tree) }
  let(:nodes) { master_tree.nodes }
  
  subject { controller }

  before do
    sign_in_as(user)
    Factory(:bookmark, :node => node)
    get :index, :master_tree_id => master_tree, :format => 'json'
  end
    
  it { should respond_with(:success) }

  it "should render the bookmarks as JSON" do
    bookmark = JSON.parse(response.body)
    bookmark.first["treepath"]["name_strings"].should == node.name_string
  end
end

describe BookmarksController, 'POST to create bookmark in master tree' do
  let(:user) { Factory(:email_confirmed_user) }
  let(:master_tree) { Factory(:master_tree, :user => user) }
  let(:node)  { Factory(:node, :tree => master_tree) }

  subject { controller }

  before do
    sign_in_as(user)
    @bookmark_count = Bookmark.count
    post :create, :master_tree_id => master_tree, :id => node, :format => 'json'
    @clone_bookmark = Bookmark.find(JSON.parse(response.body)['bookmark']['id'])
  end
  
  it 'creates a new bookmark' do
    (Bookmark.count - @bookmark_count).should == 1
  end
  
  it { should respond_with(:success) }

  it 'deletes the new bookmark' do
    @bookmark_count = Bookmark.count
    delete :destroy, :master_tree_id => master_tree, :id => @clone_bookmark.node_id, :format => 'json'
    Bookmark.count.should == 0
  end
  
  it { should respond_with(:success) }
end

describe BookmarksController, 'GET to show bookmarks for reference tree' do
  let(:user) { Factory(:email_confirmed_user) }
  let(:reference_tree) { Factory(:reference_tree) }
  let(:node)  { Factory(:node, :tree => reference_tree) }
  let(:nodes) { reference_tree.nodes }

  subject { controller }

  before do
    sign_in_as(user)
    Factory(:bookmark, :node => node)
    get :index, :reference_tree_id => reference_tree, :format => 'json'
  end
  
  it { should respond_with(:success) }
  
  it "should render the bookmarks as JSON" do
    bookmark = JSON.parse(response.body)
    bookmark.first["treepath"]["name_strings"].should == node.name_string
  end
end

describe BookmarksController, 'POST to create bookmark in reference tree' do
  let(:user) { Factory(:email_confirmed_user) }
  let(:reference_tree) { Factory(:reference_tree) }
  let(:node)  { Factory(:node, :tree => reference_tree) }

  subject { controller }

  before do
    sign_in_as(user)
    @bookmark_count = Bookmark.count
    post :create, :reference_tree_id => reference_tree, :id => node, :format => 'json'
    @clone_bookmark = Bookmark.find(JSON.parse(response.body)['bookmark']['id'])
  end
  
  it 'creates a new bookmark' do
    (Bookmark.count - @bookmark_count).should == 1
  end
  
  it { should respond_with(:success) }
  
  it 'deletes the new bookmark' do
    @bookmark_count = Bookmark.count
    delete :destroy, :reference_tree_id => reference_tree, :id => @clone_bookmark.node_id, :format => 'json'
    Bookmark.count.should == 0
  end
  
  it { should respond_with(:success) }
end

describe BookmarksController, 'GET index in master tree without authenticating' do
  before { get :index, :master_tree_id => 123 }
  it     { should redirect_to(sign_in_url) }
  it     { should set_the_flash.to(/sign in/) }
end

describe BookmarksController, 'POST create in master tree without authenticating' do
  before { post :create, :master_tree_id => 123, :id => 45 }
  it     { should redirect_to(sign_in_url) }
  it     { should set_the_flash.to(/sign in/) }
end

describe BookmarksController, 'DELETE delete in master tree without authenticating' do
  before { delete :destroy, :master_tree_id => 123, :id => 45 }
  it     { should redirect_to(sign_in_url) }
  it     { should set_the_flash.to(/sign in/) }
end

describe BookmarksController, 'GET index in reference tree without authenticating' do
  before { get :index, :reference_tree_id => 123 }
  it     { should redirect_to(sign_in_url) }
  it     { should set_the_flash.to(/sign in/) }
end

describe BookmarksController, 'POST create in reference tree without authenticating' do
  before { post :create, :reference_tree_id => 123, :id => 45 }
  it     { should redirect_to(sign_in_url) }
  it     { should set_the_flash.to(/sign in/) }
end

describe BookmarksController, 'DELETE delete in reference tree without authenticating' do
  before { delete :destroy, :reference_tree_id => 123, :id => 45 }
  it     { should redirect_to(sign_in_url) }
  it     { should set_the_flash.to(/sign in/) }
end

describe BookmarksController, 'DELETE delete in reference tree without authenticating' do
  before { delete :destroy, :reference_tree_id => 123, :id => 45 }
  it     { should redirect_to(sign_in_url) }
  it     { should set_the_flash.to(/sign in/) }
end