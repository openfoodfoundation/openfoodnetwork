# frozen_string_literal: true

RSpec.describe Orders::WebhookService do
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:order) { create(:completed_order_with_totals, order_cycle:) }
  let!(:payment) { create(:payment, order:) }

  before { order.payments.reload }

  subject { described_class.create_payment_due_job(order:) }

  describe "creating payloads" do
    context "with order cycle coordinator owner webhook endpoints configured" do
      before do
        order.order_cycle.coordinator.owner.webhook_endpoints.payment_status.create!(
          url: "http://coordinator.payment.url"
        )
      end

      it "enqueues an order.payment_due delivery for the coordinator owner" do
        expect{ subject }
          .to enqueue_job(WebhookDeliveryJob).exactly(1).times
          .with("http://coordinator.payment.url", "order.payment_due", any_args)
      end

      it "includes the order, amount due and payment method in the payload" do
        data = {
          order: {
            number: order.number,
            email: order.email,
            total: order.total,
            currency: order.currency,
            outstanding_balance: order.new_outstanding_balance
          },
          payment_method: {
            name: payment.payment_method.name,
            type: payment.payment_method.type
          }
        }

        expect{ subject }
          .to enqueue_job(WebhookDeliveryJob).exactly(1).times
          .with("http://coordinator.payment.url", "order.payment_due", hash_including(data))
      end

      context "with coordinator managers with webhook endpoints configured" do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }

        before do
          coordinator = order.order_cycle.coordinator
          coordinator.users << user1
          coordinator.users << user2
        end

        it "enqueues a delivery for every unique configured endpoint" do
          user1.webhook_endpoints.payment_status.create!(url: "http://coordinator.payment.url")
          user2.webhook_endpoints.payment_status.create!(url: "http://user2.payment.url")

          expect{ subject }
            .to enqueue_job(WebhookDeliveryJob)
            .with("http://coordinator.payment.url", "order.payment_due", any_args)
            .and enqueue_job(WebhookDeliveryJob)
            .with("http://user2.payment.url", "order.payment_due", any_args)
        end
      end
    end

    context "with no webhook configured" do
      it "does not enqueue a delivery" do
        expect{ subject }.not_to enqueue_job(WebhookDeliveryJob)
      end
    end
  end
end
