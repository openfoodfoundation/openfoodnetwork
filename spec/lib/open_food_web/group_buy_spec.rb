require 'spec_helper'

module OpenFoodWeb
  describe GroupBuyReport do

    before(:each) do
      @bill_address = create(:address)
      @distributor_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
      @distributor = create(:distributor, :pickup_address => @distributor_address)
      product = create(:product)
      product_distribution = create(:product_distribution, :product => product, :distributor => @distributor, :shipping_method => create(:shipping_method))
      @shipping_instructions = "pick up on thursday please!"
      @order = create(:order, :distributor => @distributor, :bill_address => @bill_address, :special_instructions => @shipping_instructions)
      @payment_method = create(:payment_method)
      payment = create(:payment, :payment_method => @payment_method, :order => @order )
      @order.payments << payment
      @line_item = create(:line_item, :product => product, :order => @order)
      @order.line_items << @line_item
    end

    it "should return a header row describing the report" do
      subject = GroupBuyReport.new [@order]

      header = subject.header
      header.should == ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Total Ordered", "Total Max"]
    end

  end
end