class ReferenceTreesController < ApplicationController

  def create
    respond_to do |format|
      format.json do
        tree_params = params[:reference_tree].merge(:user_id => current_user.id)
        node_list = params[:nodes_list]
        logger.debug(node_list)
        reference_tree = ReferenceTree.create_from_list(tree_params, node_list)
        render :json => reference_tree, :status => :created
      end
    end
  end

  def show
    @reference_tree = ReferenceTree.find(params[:id])
  end
end
