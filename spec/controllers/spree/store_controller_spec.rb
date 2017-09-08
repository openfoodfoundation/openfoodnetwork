require 'spec_helper'

describe Spree::StoreController, type: :controller do
  controller(Spree::StoreController) do
    before_filter :unauthorized
    def index
      render text: ""
    end
  end
  it "redirects to home when unauthorized" do
    get :index
    response.should render_template("shared/unauthorized", layout: 'darkswarm')
  end
end
