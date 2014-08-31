require 'spec_helper'

describe Spree::Admin::BaseController do
  controller(Spree::Admin::BaseController) do
    def index
      before_filter :unauthorized
      render text: ""
    end
  end

  it "redirects to Angular login" do
    get :index
    response.should redirect_to root_path(anchor: "login?after_login=/anonymous")
  end
end
