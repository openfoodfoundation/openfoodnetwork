# frozen_string_literal: true

RSpec.describe Payments::WebhookPayload do
  describe "#to_hash" do
    let(:order) { create(:completed_order_with_totals, order_cycle: ) }
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:payment) { create(:payment, :completed, amount: order.total, order:) }
    let(:tax_category) { create(:tax_category) }

    subject { described_class.new(payment:, order:, enterprise: order.distributor) }

    it "returns a hash with the relevant data" do
      order.line_items.update_all(tax_category_id: tax_category.id)

      enterprise = order.distributor
      line_items = order.line_items.map do |li|
        {
          quantity: li.quantity,
          price: li.price,
          tax_category_name: li.tax_category&.name,
          product_name: li.product.name,
          name_to_display: li.display_name,
          unit_to_display: li.unit_presentation
        }
      end

      payload = {
        payment: {
          updated_at: payment.updated_at,
          amount: payment.amount,
          state: payment.state
        },
        enterprise: {
          abn: enterprise.abn,
          acn: enterprise.acn,
          name: enterprise.name,
          address: {
            address1: enterprise.address.address1,
            address2: enterprise.address.address2,
            city: enterprise.address.city,
            zipcode: enterprise.address.zipcode
          }
        },
        order: {
          total: order.total,
          currency: order.currency,
          line_items: line_items
        }
      }.with_indifferent_access

      expect(subject.to_hash).to eq(payload)
    end
  end

  describe ".test_data" do
    it "returns a hash with test data" do
      test_payload = {
        payment: {
          updated_at: kind_of(Time),
          amount: 0.00,
          state: "completed"
        },
        enterprise: {
          abn: "65797115831",
          acn: "",
          name: "TEST Enterprise",
          address: {
            address1: "1 testing street",
            address2: "",
            city: "TestCity",
            zipcode: "1234"
          }
        },
        order: {
          total: 0.00,
          currency: "AUD",
          line_items: [
            {
              quantity: 1,
              price: 20.00.to_d,
              tax_category_name: "VAT",
              product_name: "Test product",
              name_to_display: nil,
              unit_to_display: "1kg"
            }
          ]
        }
      }.with_indifferent_access

      expect(described_class.test_data.to_hash).to match(test_payload)
    end
  end
end
