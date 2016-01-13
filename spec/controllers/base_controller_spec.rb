require 'spec_helper'

describe BaseController, :type => :controller do
  let(:oc)    { mock_model(OrderCycle) }
  let(:hub)   { mock_model(Enterprise, ready_for_checkout?: true) }
  let(:order) { mock_model(Spree::Order, distributor: hub) }
  controller(BaseController) do
    def index
      render text: ""
    end
  end

  it "redirects to home with message if order cycle is expired" do
    controller.stub(:current_order_cycle).and_return(oc)
    controller.stub(:current_order).and_return(order)
    oc.stub(:closed?).and_return(true)

    order.should_receive(:empty!)
    order.should_receive(:set_order_cycle!).with(nil)

    get :index

    session[:expired_order_cycle_id].should == oc.id
    response.should redirect_to root_url
    flash[:info].should == "The order cycle you've selected has just closed. Please try again!"
  end
end
