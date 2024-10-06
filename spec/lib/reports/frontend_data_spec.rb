# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Reporting::FrontendData do
  subject { described_class.new(user) }

  let(:user) { create(:user, enterprises: [distributor1, distributor2]) }
  let(:distributor1) { create(:distributor_enterprise) }
  let(:distributor2) { create(:distributor_enterprise) }

  let(:supplier1) { create(:supplier_enterprise) }
  let(:supplier2) { create(:supplier_enterprise) }
  let(:supplier3) { create(:supplier_enterprise) }

  let(:product1) { create(:simple_product, name: "Product Supplier 1", supplier_id: supplier1.id) }
  let(:product2) { create(:simple_product, name: "Product Supplier 2", supplier_id: supplier2.id) }
  let(:product3) { create(:simple_product, name: "Product Supplier 3", supplier_id: supplier3.id) }

  let(:order_cycle1) {
    create(:simple_order_cycle, coordinator: distributor1,
                                distributors: [distributor1],
                                variants: [product1.variants.first, product2.variants.first])
  }

  let(:order_cycle2) {
    create(:simple_order_cycle, coordinator: distributor2,
                                distributors: [distributor2],
                                variants: [product3.variants.first])
  }

  let!(:order1) {
    create(:order, order_cycle: order_cycle1, distributor: distributor1)
  }
  let!(:order2) {
    create(:order, order_cycle: order_cycle2, distributor: distributor2)
  }

  describe "#suppliers_of_products_distributed_by" do
    it "returns supplier of products for the given distributors" do
      distributors = Enterprise.where(id: [distributor1, distributor2])

      expect(subject.suppliers_of_products_distributed_by(distributors)).to match_array(
        [supplier1, supplier2, supplier3]
      )
    end
  end
end
