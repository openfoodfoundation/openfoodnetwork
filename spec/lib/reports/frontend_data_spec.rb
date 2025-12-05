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

  describe "#order_customers" do
    let!(:customer1) { create(:customer, enterprise: distributor1, email: "customer1@example.com") }
    let!(:customer2) { create(:customer, enterprise: distributor2, email: "customer2@example.com") }

    let!(:order_with_customer1) do
      create(:completed_order_with_totals, order_cycle: order_cycle1,
                                           distributor: distributor1,
                                           customer: customer1)
    end

    let!(:order_with_customer2) do
      create(:completed_order_with_totals, order_cycle: order_cycle2,
                                           distributor: distributor2,
                                           customer: customer2)
    end

    it "returns distinct customers with only id and email fields from visible orders" do
      customers = subject.order_customers
      customer_emails = customers.pluck('email')
      customers_data = customers.pluck(:id, :email)

      expect(customer_emails).to contain_exactly(customer1.email, customer2.email)
      expect(customers_data.first.length).to eq(2)
      expect(customers_data.first[0]).to be_an(Integer)
      expect(customers_data.first[1]).to be_a(String)
    end

    it "returns distinct customers even with duplicate orders" do
      # Create duplicate order for same customer
      create(:completed_order_with_totals, order_cycle: order_cycle1,
                                           distributor: distributor1,
                                           customer: customer1)

      customer_emails = subject.order_customers.pluck('email')

      expect(customer_emails.count(customer1.email)).to eq(1)
    end

    it "respects permissions - only returns customers from managed distributor orders" do
      user_with_one_distributor = create(:user, enterprises: [distributor1])
      frontend_data = described_class.new(user_with_one_distributor)

      customer_emails = frontend_data.order_customers.pluck('email')

      expect(customer_emails).to contain_exactly(customer1.email)
      expect(customer_emails).not_to include(customer2.email)
    end

    context "when user coordinates order cycles" do
      let(:coordinator) { create(:distributor_enterprise) }
      let(:user_coordinator) { create(:user, enterprises: [coordinator]) }
      let(:other_distributor) { create(:distributor_enterprise) }
      let(:customer3) {
        create(:customer, enterprise: other_distributor, email: "customer3@example.com")
      }
      let(:coordinated_order_cycle) do
        create(:simple_order_cycle, coordinator: coordinator,
                                    distributors: [other_distributor],
                                    variants: [product1.variants.first])
      end

      let!(:coordinated_order) do
        create(:completed_order_with_totals, order_cycle: coordinated_order_cycle,
                                             distributor: other_distributor,
                                             customer: customer3)
      end

      it "includes customers from coordinated order cycles" do
        customer_emails = described_class.new(user_coordinator).order_customers.pluck('email')

        expect(customer_emails).to include(customer3.email)
      end
    end

    context "when user is a producer with P-OC permissions" do
      let(:producer) { create(:supplier_enterprise) }
      let(:user_producer) { create(:user, enterprises: [producer]) }
      let(:hub) { create(:distributor_enterprise) }
      let(:customer4) { create(:customer, enterprise: hub, email: "customer4@example.com") }
      let(:producer_product) { create(:simple_product, supplier_id: producer.id) }
      let(:producer_variant) { producer_product.variants.first }

      let!(:enterprise_relationship) do
        create(:enterprise_relationship, parent: producer, child: hub,
                                         permissions_list: [:add_to_order_cycle])
      end

      let(:producer_order_cycle) do
        create(:simple_order_cycle, coordinator: hub,
                                    distributors: [hub],
                                    variants: [producer_variant])
      end

      let!(:producer_order) do
        order = create(:completed_order_with_totals, order_cycle: producer_order_cycle,
                                                     distributor: hub,
                                                     customer: customer4)
        order.line_items.first.update!(variant: producer_variant)
        order
      end

      it "includes customers from orders with producer's products" do
        customer_emails = described_class.new(user_producer).order_customers.pluck('email')

        expect(customer_emails).to include(customer4.email)
      end
    end
  end
end
