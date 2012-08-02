require 'spec_helper'


module OpenFoodWeb
  describe OrderAndDistributorReport do

    describe "orders and distributors report" do

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
        subject = OrderAndDistributorReport.new [@order]

        header = subject.header
        header.should == ["Order date", "Order Id",
          "Customer Name","Customer Email", "Customer Phone", "Customer City",
          "SKU", "Item name", "Variant", "Quantity", "Max Quantity", "Cost", "Shipping cost",
          "Payment method",
          "Distributor", "Distributor address", "Distributor city", "Distributor postcode", "Shipping instructions"]
      end

      it "should denormalise order and distributor details for display as csv" do
        subject = OrderAndDistributorReport.new [@order]

        table = subject.table

        table[0].should == [@order.created_at, @order.id,
          @bill_address.full_name, @order.email, @bill_address.phone, @bill_address.city,
          @line_item.product.sku, @line_item.product.name, @line_item.variant.options_text, @line_item.quantity, @line_item.max_quantity, @line_item.price * @line_item.quantity, @line_item.itemwise_shipping_cost,
          @payment_method.name,
          @distributor.name, @distributor.pickup_address.address1, @distributor.pickup_address.city, @distributor.pickup_address.zipcode, @shipping_instructions ]
      end

      it "should include breakdown an order into each line item"

    end
  end
end
