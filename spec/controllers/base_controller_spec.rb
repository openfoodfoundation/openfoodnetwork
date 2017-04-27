require 'spec_helper'

describe BaseController, :type => :controller do
  let(:oc)    { instance_double(OrderCycle, id: 1) }
  let(:order) { instance_double(Spree::Order) }
  controller(BaseController) do
    def index
      render text: ""
    end
  end

  it "redirects to home with message if order cycle is expired" do
    expect(controller).to receive(:current_order_cycle).and_return(oc).twice
    expect(controller).to receive(:current_order).and_return(order).twice
    expect(oc).to receive(:closed?).and_return(true)
    expect(order).to receive(:empty!)
    expect(order).to receive(:set_order_cycle!).with(nil)

    get :index

    expect(session[:expired_order_cycle_id]).to eq oc.id
    expect(response).to redirect_to root_url
    expect(flash[:info]).to eq "The order cycle you've selected has just closed. Please try again!"
  end
end
