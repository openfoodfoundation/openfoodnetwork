# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe AffiliateSalesDataBuilder do
  let(:user) { build(:user) }

  describe ".person" do
    let(:person) { described_class.person(user) }

    it "returns data as Person" do
      expect(person).to be_a DataFoodConsortium::Connector::Person
      expect(person.semanticId).to eq "http://test.host/api/dfc/affiliate_sales_data"
    end

    it "returns required sales data" do
      supplier = create(
        :supplier_enterprise,
        owner: user,
        users: [user],
        address: create(:address, zipcode: "5555"),
      )
      product = create(
        :product,
        supplier_id: supplier.id,
        variant_unit: "item",
      )
      variant = product.variants.first
      distributor = create(
        :distributor_enterprise,
        address: create(:address, zipcode: "6666"),
      )
      line_item = build(
        :line_item,
        variant:,
        quantity: 2,
        price: 3,
      )
      order_cycle = create(
        :order_cycle,
        suppliers: [supplier],
        distributors: [distributor],
      )
      order_cycle.exchanges.incoming.first.variants << variant
      order_cycle.exchanges.outgoing.first.variants << variant
      create(
        :order,
        order_cycle:,
        distributor:,
        line_items: [line_item],
      )
    end
  end
end
