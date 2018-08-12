require 'spec_helper'

describe CartController, type: :controller do
  let(:order) { create(:order) }

  describe "returning stock levels in JSON on success" do
    let(:product) { create(:simple_product) }

    it "returns stock levels as JSON" do
      controller.stub(:variant_ids_in) { [123] }
      controller.stub(:stock_levels) { 'my_stock_levels' }
      Spree::OrderPopulator.stub(:new).and_return(populator = double())
      populator.stub(:populate) { true }
      populator.stub(:variants_h) { {} }

      xhr :post, :populate, use_route: :spree, format: :json

      data = JSON.parse(response.body)
      data['stock_levels'].should == 'my_stock_levels'
    end

    describe "generating stock levels" do
      let!(:order) { create(:order) }
      let!(:li) { create(:line_item, order: order, variant: v, quantity: 2, max_quantity: 3) }
      let!(:v) { create(:variant, count_on_hand: 4) }
      let!(:v2) { create(:variant, count_on_hand: 2) }

      before do
        order.reload
        controller.stub(:current_order) { order }
      end

      it "returns a hash with variant id, quantity, max_quantity and stock on hand" do
        controller.stock_levels(order, [v.id]).should ==
          {v.id => {quantity: 2, max_quantity: 3, on_hand: 4}}
      end

      it "includes all line items, even when the variant_id is not specified" do
        controller.stock_levels(order, []).should ==
          {v.id => {quantity: 2, max_quantity: 3, on_hand: 4}}
      end

      it "includes an empty quantity entry for variants that aren't in the order" do
        controller.stock_levels(order, [v.id, v2.id]).should ==
          {v.id  => {quantity: 2, max_quantity: 3, on_hand: 4},
           v2.id => {quantity: 0, max_quantity: 0, on_hand: 2}}
      end

      describe "encoding Infinity" do
        let!(:v) { create(:variant, on_demand: true, count_on_hand: 0) }

        it "encodes Infinity as a large, finite integer" do
          controller.stock_levels(order, [v.id]).should ==
            {v.id => {quantity: 2, max_quantity: 3, on_hand: 2147483647}}
        end
      end
    end

    it "extracts variant ids from the populator" do
      variants_h = [{:variant_id=>"900", :quantity=>2, :max_quantity=>nil},
       {:variant_id=>"940", :quantity=>3, :max_quantity=>3}]

      controller.variant_ids_in(variants_h).should == [900, 940]
    end
  end

  context "adding a group buy product to the cart" do
    it "sets a variant attribute for the max quantity" do
      distributor_product = create(:distributor_enterprise)
      p = create(:product, :distributors => [distributor_product], :group_buy => true)

      order = subject.current_order(true)
      order.stub(:distributor) { distributor_product }
      order.should_receive(:set_variant_attributes).with(p.master, {'max_quantity' => '3'})
      controller.stub(:current_order).and_return(order)

      expect do
        spree_post :populate, :variants => {p.master.id => 1}, :variant_attributes => {p.master.id => {:max_quantity => 3}}
      end.to change(Spree::LineItem, :count).by(1)
    end

    it "returns HTTP success when successful" do
      Spree::OrderPopulator.stub(:new).and_return(populator = double())
      populator.stub(:populate) { true }
      populator.stub(:variants_h) { {} }
      xhr :post, :populate, use_route: :spree, format: :json
      response.status.should == 200
    end

    it "returns failure when unsuccessful" do
      Spree::OrderPopulator.stub(:new).and_return(populator = double())
      populator.stub(:populate).and_return false
      xhr :post, :populate, use_route: :spree, format: :json
      response.status.should == 412
    end

    it "tells populator to overwrite" do
      Spree::OrderPopulator.stub(:new).and_return(populator = double())
      populator.should_receive(:populate).with({}, true)
      xhr :post, :populate, use_route: :spree, format: :json
    end
  end
end

