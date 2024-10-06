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

    describe "with sales data" do
      before do
        supplier = create(
          :supplier_enterprise,
          owner: user,
          users: [user],
          address: create(:address, zipcode: "5555"),
        )
        product = create(
          :product,
          name: "Pomme",
          supplier_id: supplier.id,
          variant_unit: "items",
          variant_unit_name: "bag",
        )
        variant = product.variants.first
        distributor = create(
          :distributor_enterprise,
          owner: user,
          address: create(:address, zipcode: "6666"),
        )
        ConnectedApps::AffiliateSalesData.new(enterprise: distributor).connect({})
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
          state: "complete",
          order_cycle:,
          distributor:,
          line_items: [line_item],
        )
      end

      it "returns required sales data", feature: :affiliate_sales_data do
        supplier = person.affiliatedOrganizations[0]
        product = supplier.suppliedProducts[0]
        line = product.semanticPropertyValue("dfc-b:concernedBy")
        session = line.order.saleSession
        coordination = session.semanticPropertyValue("dfc-b:objectOf")
        distributor = coordination.coordinator

        expect(supplier.localizations[0].postalCode).to eq "5555"
        expect(distributor.localizations[0].postalCode).to eq "6666"

        expect(product.name).to eq "Pomme"
        expect(product.quantity.unit).to eq DfcLoader.connector.MEASURES.PIECE
        expect(product.quantity.value).to eq 1

        expect(line.quantity.unit).to eq DfcLoader.connector.MEASURES.PIECE
        expect(line.quantity.value).to eq 2
        expect(line.price.value).to eq 3
      end
    end
  end
end
