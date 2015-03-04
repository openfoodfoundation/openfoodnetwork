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

  describe "displaying error messages for active distributors not ready for checkout" do
    it "generates an error message when there is one distributor" do
      distributor = double(:distributor, name: 'My Hub')
      controller.
        send(:active_distributors_not_ready_for_checkout_message, [distributor]).
        should ==
        "The hub My Hub is listed in an active order cycle, " +
        "but does not have valid shipping and payment methods. " +
        "Until you set these up, customers will not be able to shop at this hub."
    end

    it "generates an error message when there are several distributors" do
      d1 = double(:distributor, name: 'Hub One')
      d2 = double(:distributor, name: 'Hub Two')
      controller.
        send(:active_distributors_not_ready_for_checkout_message, [d1, d2]).
        should ==
        "The hubs Hub One, Hub Two are listed in an active order cycle, " +
        "but do not have valid shipping and payment methods. " +
        "Until you set these up, customers will not be able to shop at these hubs."
    end
  end
end
