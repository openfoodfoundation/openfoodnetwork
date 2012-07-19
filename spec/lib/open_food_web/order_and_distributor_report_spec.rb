require 'spec_helper'


module OpenFoodWeb
  describe OrderAndDistributorReport do

    describe "orders and distributors report" do
      let(:bill_address) { create(:address) }
      let(:distributor_address) { create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234") }
      let(:distributor) { create(:distributor, :pickup_address => distributor_address) }
      let(:product) do
        product = create(:product)
        product_distribution = create(:product_distribution, :product => product, :distributor => distributor, :shipping_method => create(:shipping_method))
        product
      end
      let(:order) do
        create(:order, :distributor => distributor, :bill_address => bill_address)
      end
      let(:line_item) do
        line_item = create(:line_item, :product => product, :order => order)
        order.line_items << line_item
        line_item
      end


      it "should return a header row describing the report" do
        subject = OrderAndDistributorReport.new [order]

        header = subject.header
        header.should == ["Order date", "Order Id", "Name","Email", "SKU", "Item cost", "Quantity", "Cost", "Shipping cost", "Distributor", "Distributor address", "Distributor city", "Distributor postcode"]
      end

      it "should denormalise order and distributor details for display as csv" do
        subject = OrderAndDistributorReport.new [order]

        table = subject.table

        table[0].should == [order.created_at, order.id, bill_address.full_name, order.user.email,
            line_item.product.sku, line_item.product.name, line_item.quantity, line_item.price * line_item.quantity, line_item.itemwise_shipping_cost,
            distributor.name, distributor.pickup_address.address1, distributor.pickup_address.city, distributor.pickup_address.zipcode ]
      end

      it "should include breakdown an order into each line item"

    end
  end
end