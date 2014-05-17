require 'spec_helper'

describe BaseController do
  let(:oc) { mock_model(OrderCycle) }
  let(:order) { mock_model(Spree::Order) }
  controller(BaseController) do
    def index
      render text: ""
    end
  end
  it "redirects to home with message if order cycle is expired" do
    controller.stub(:current_order_cycle).and_return oc
    controller.stub(:current_order).and_return order
    order.stub(:empty!)
    order.stub(:set_order_cycle!)
    oc.stub(:closed?).and_return true
    get :index
    response.should redirect_to root_url
    flash[:notice].should == "The order cycle you've selected has just closed. Please try again!"
  end
end
