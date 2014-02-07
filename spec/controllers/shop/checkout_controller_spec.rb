require 'spec_helper'

describe Shop::CheckoutController do
  it "redirects home when no distributor is selected" do
    get :new
    response.should redirect_to root_path
  end

  it "redirects to the shop when no order cycle is selected" do
    controller.stub(:current_distributor).and_return(double(:distributor))
    get :new
    response.should redirect_to shop_path
  end

  it "renders when both distributor and order cycle is selected" do
    controller.stub(:current_distributor).and_return(double(:distributor))
    controller.stub(:order_cycle).and_return(double(:order_cycle))
    get :new
    response.should be_success
  end
end
