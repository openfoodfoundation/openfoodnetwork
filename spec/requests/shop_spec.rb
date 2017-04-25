require 'spec_helper'

describe "Shop API", type: :request do
  include ShopWorkflow

  describe "filtering products" do
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:oc1) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now) }
    let(:p4) { create(:simple_product, on_demand: false) }
    let(:p5) { create(:simple_product, on_demand: false) }
    let(:p6) { create(:simple_product, on_demand: false) }
    let(:p7) { create(:simple_product, on_demand: false) }
    let(:v41) { p4.variants.first }
    let(:v42) { create(:variant, product: p4, unit_value: 3, on_demand: false) }
    let(:v43) { create(:variant, product: p4, unit_value: 4, on_demand: true) }
    let(:v51) { p5.variants.first }
    let(:v52) { create(:variant, product: p5) }
    let(:v61) { p6.variants.first }
    let(:v71) { p7.variants.first }
    let(:order) { create(:order, distributor: distributor, order_cycle: oc1) }

    before do
      set_order order

      v61.update_attribute(:count_on_hand, 1)
      p6.delete
      v71.update_attribute(:count_on_hand, 1)
      v41.update_attribute(:count_on_hand, 1)
      v42.update_attribute(:count_on_hand, 0)
      v43.update_attribute(:count_on_hand, 0)
      v51.update_attribute(:count_on_hand, 1)
      v52.update_attribute(:count_on_hand, 0)
      v71.update_attribute(:count_on_hand, 1)
      v71.update_attribute(:deleted_at, Time.zone.now)
      exchange = Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id)
      exchange.update_attribute :pickup_time, "frogs"
      exchange.variants << v61
      exchange.variants << v41
      exchange.variants << v42
      exchange.variants << v43
      # v51 is in stock but not in distribution
      # v52 is out of stock and in the distribution
      # Neither should display, nor should their product, p5
      exchange.variants << v52
      exchange.variants << v71
      get products_shop_path
    end

    it "filters products based on availability" do
      # It shows on demand variants
      expect(response.body).to include v43.options_text
      # It does not show variants that are neither on hand or on demand
      expect(response.body).not_to include v42.options_text
      # It does not show products that have no available variants in this distribution
      expect(response.body).not_to include p5.name
      # It does not show deleted products
      expect(response.body).not_to include p6.name
      # It does not show deleted variants
      expect(response.body).not_to include v71.name
      expect(response.body).not_to include p7.name
    end
  end
end
