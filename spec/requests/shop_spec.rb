require 'spec_helper'

describe "Shop API" do
  include ShopWorkflow

  describe "filtering products" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:oc1) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now) }
    let(:p1) { create(:simple_product, on_demand: false) }
    let(:p2) { create(:simple_product, on_demand: true) }
    let(:p3) { create(:simple_product, on_demand: false) }
    let(:p4) { create(:simple_product, on_demand: false) }
    let(:p5) { create(:simple_product, on_demand: false) }
    let(:p6) { create(:simple_product, on_demand: false) }
    let(:p7) { create(:simple_product, on_demand: false) }
    let(:v1) { create(:variant, product: p4, unit_value: 2) }
    let(:v2) { create(:variant, product: p4, unit_value: 3, on_demand: false) }
    let(:v3) { create(:variant, product: p4, unit_value: 4, on_demand: true) }
    let(:v4) { create(:variant, product: p5) }
    let(:v5) { create(:variant, product: p5) }
    let(:v6) { create(:variant, product: p7) }
    let(:order) { create(:order, distributor: distributor, order_cycle: oc1) }

    before do
      set_order order

      p1.master.update_attribute(:count_on_hand, 1)
      p2.master.update_attribute(:count_on_hand, 0)
      p3.master.update_attribute(:count_on_hand, 0)
      p6.master.update_attribute(:count_on_hand, 1)
      p6.delete
      p7.master.update_attribute(:count_on_hand, 1)
      v1.update_attribute(:count_on_hand, 1)
      v2.update_attribute(:count_on_hand, 0)
      v3.update_attribute(:count_on_hand, 0)
      v4.update_attribute(:count_on_hand, 1)
      v5.update_attribute(:count_on_hand, 0)
      v6.update_attribute(:count_on_hand, 1)
      v6.update_attribute(:deleted_at, Time.now)
      exchange = Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) 
      exchange.update_attribute :pickup_time, "frogs" 
      exchange.variants << p1.master
      exchange.variants << p2.master
      exchange.variants << p3.master
      exchange.variants << p6.master
      exchange.variants << v1
      exchange.variants << v2
      exchange.variants << v3
      # v4 is in stock but not in distribution
      # v5 is out of stock and in the distribution
      # Neither should display, nor should their product, p5
      exchange.variants << v5
      exchange.variants << v6
      get products_shop_path
    end

    it "filters products based on availability" do
      # It shows on hand products
      response.body.should include p1.name
      response.body.should include p4.name
      # It shows on demand products
      response.body.should include p2.name
      # It does not show products that are neither on hand or on demand
      response.body.should_not include p3.name
      # It shows on demand variants
      response.body.should include v3.options_text
      # It does not show variants that are neither on hand or on demand
      response.body.should_not include v2.options_text
      # It does not show products that have no available variants in this distribution
      response.body.should_not include p5.name
      # It does not show deleted products
      response.body.should_not include p6.name
      # It does not show deleted variants
      response.body.should_not include v6.name
      response.body.should_not include p7.name
    end
  end
end
