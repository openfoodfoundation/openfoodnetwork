# frozen_string_literal: true

RSpec.describe Payments::WebhookService do
  let(:order) { create(:completed_order_with_totals, order_cycle: ) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:payment) { create(:payment, :completed, amount: order.total, order:) }
  let(:tax_category) { create(:tax_category) }
  let(:at) { Time.zone.parse("2025-11-26 09:00:02") }

  subject { described_class.create_webhook_job(payment: payment, event: "payment.completed", at:) }

  describe "creating payloads" do
    context "with order cycle coordinator owner webhook endpoints configured" do
      before do
        order.order_cycle.coordinator.owner.webhook_endpoints.payment_status.create!(
          url: "http://coordinator.payment.url"
        )
      end

      it "calls endpoint for the owner if the order cycle coordinator" do
        expect{ subject }
          .to enqueue_job(WebhookDeliveryJob).exactly(1).times
          .with("http://coordinator.payment.url", "payment.completed", any_args)
      end

      it "creates webhook payload with payment details" do
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

        data = {
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
        }

        expect{ subject }
          .to enqueue_job(WebhookDeliveryJob).exactly(1).times
          .with("http://coordinator.payment.url", "payment.completed", hash_including(data), at:)
      end

      context "with coordinator manager with webhook endpoint configured" do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }

        before do
          coordinator = order.order_cycle.coordinator
          coordinator.users << user1
          coordinator.users << user2
        end

        it "calls endpoint for all user managing the order cycle coordinator" do
          user1.webhook_endpoints.payment_status.create!(url: "http://user1.payment.url")
          user2.webhook_endpoints.payment_status.create!(url: "http://user2.payment.url")

          expect{ subject }
            .to enqueue_job(WebhookDeliveryJob)
            .with("http://coordinator.payment.url", "payment.completed", any_args)
            .and enqueue_job(WebhookDeliveryJob)
            .with("http://user1.payment.url", "payment.completed", any_args)
            .and enqueue_job(WebhookDeliveryJob)
            .with("http://user2.payment.url", "payment.completed", any_args)
        end

        context "wiht duplicate webhook endpoints configured" do
          it "calls each unique configured endpoint" do
            user1.webhook_endpoints.payment_status.create!(url: "http://coordinator.payment.url")
            user2.webhook_endpoints.payment_status.create!(url: "http://user2.payment.url")

            expect{ subject }
              .to enqueue_job(WebhookDeliveryJob)
              .with("http://coordinator.payment.url", "payment.completed", any_args)
              .and enqueue_job(WebhookDeliveryJob)
              .with("http://user2.payment.url", "payment.completed", any_args)
          end
        end
      end
    end

    context "with no webhook configured" do
      it "does not call endpoint" do
        expect{ subject }.not_to enqueue_job(WebhookDeliveryJob)
      end
    end
  end
end
