require 'spec_helper'

describe EnterprisesController do
  it "displays suppliers" do
    s = create(:supplier_enterprise)
    d = create(:distributor_enterprise)

    spree_get :suppliers

    assigns(:suppliers).should == [s]
  end

  context 'shopping for a distributor' do

    before(:each) do
      @current_distributor = create(:distributor_enterprise)
      @distributor = create(:distributor_enterprise)
      controller.current_order(true).distributor = @current_distributor
    end

    it "sets the shop as the distributor on the order when shopping for the distributor" do
      spree_get :shop, {id: @distributor}

      controller.current_order.distributor.should == @distributor
    end

    it "empties an order that was set for a previous distributor, when shopping at a new distributor" do
      line_item = create(:line_item)
      controller.current_order.line_items << line_item

      spree_get :shop, {id: @distributor}

      controller.current_order.distributor.should == @distributor
      controller.current_order.line_items.size.should == 0
    end

    it "should not empty an order if returning to the same distributor" do
      product = create(:product)
      create(:product_distribution, product: product, distributor: @current_distributor)
      line_item = create(:line_item, variant: product.master)
      controller.current_order.line_items << line_item

      spree_get :shop, {id: @current_distributor}

      controller.current_order.distributor.should == @current_distributor
      controller.current_order.line_items.size.should == 1
    end
  end
end
