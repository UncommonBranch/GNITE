require 'spec_helper'

describe HomesController do

  context "on GET to #show" do
    before do
      get :show
    end

    subject { controller }

    it { should respond_with(:success) }
  end

end
