require 'spec_helper'

describe ImportsController, type: :controller do
  context "when signed out" do
    context "on GET to new" do
      before do
        get :new, master_tree_id: 123
      end

      subject { controller }

      it { should redirect_to(new_user_session_url) }
      it { should set_the_flash.to(/sign in/) }
    end
  end

  context "signed in" do
    let(:user) { create(:user) }

    before do
      sign_in user
      controller.stubs(current_user: user)
    end

    context "GET to #new with a master_tree_id" do
      let(:master_tree)  { create(:master_tree, user_id: user.id) }
      let(:master_trees) { [master_tree] }

      before do
        MasterTree.stubs(find: master_tree)
        get :new, master_tree_id: master_tree.to_param
      end

      subject { controller }

      it { should respond_with(:success) }
      it { should render_template('new') }

      it 'should assign_to(:master_tree).with(master_tree)' do
        assigns(:master_tree).should == master_tree
      end

      it "should find the correct master tree" do
        MasterTree.should have_received(:find).with(master_tree.to_param)
      end
    end
  end
end
