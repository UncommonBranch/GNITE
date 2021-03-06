class GnaclrSearchesController < ApplicationController
  before_filter :authenticate_user!

  def show
    respond_to do |wants|
      wants.js do
        begin
          @results     = GnaclrSearch.new(search_term: params[:search_term]).results
          @master_tree = MasterTree.find(params[:master_tree_id])
        rescue Gnite::ServiceUnavailable
          head :service_unavailable
          return
        end
        render :show, layout: false
      end
      wants.html { head :bad_request }
    end
  end
end
