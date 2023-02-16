# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleWebhookService do
  let(:order_cycle) {
    create(
      :simple_order_cycle,
      name: "Order cycle 1",
      orders_open_at: "2022-09-19 09:00:00".to_time,
      orders_close_at: "2022-09-19 17:00:00".to_time,
      coordinator: coordinator,
    )
  }
  let(:coordinator) { create :distributor_enterprise, name: "Starship Enterprise" }

  describe "creating payloads" do
    it "doesn't create webhook payload for enterprise users" do
      # The co-ordinating enterprise has a non-owner user with an endpoint.
      # They shouldn't receive a notification.
      coordinator_user = create(:user, enterprises: [coordinator])
      coordinator_user.webhook_endpoints.create!(url: "http://coordinator_user_url")

      expect{ OrderCycleWebhookService.create_webhook_job(order_cycle, "order_cycle.opened") }
        .to_not enqueue_job(WebhookDeliveryJob).with("http://coordinator_user_url", any_args)
    end

    context "coordinator owner has endpoint configured" do
      before do
        coordinator.owner.webhook_endpoints.create! url: "http://coordinator_owner_url"
      end

      it "creates webhook payload for order cycle coordinator" do
        expect{ OrderCycleWebhookService.create_webhook_job(order_cycle, "order_cycle.opened") }
          .to enqueue_job(WebhookDeliveryJob).with("http://coordinator_owner_url", any_args)
      end

      it "creates webhook payload with details for the specified order cycle only" do
        # The coordinating enterprise has another OC. It should be ignored.
        order_cycle.dup.save

        data = {
          id: order_cycle.id,
          name: "Order cycle 1",
          orders_open_at: "2022-09-19 09:00:00".to_time,
          orders_close_at: "2022-09-19 17:00:00".to_time,
          coordinator_id: coordinator.id,
          coordinator_name: "Starship Enterprise",
        }

        expect{ OrderCycleWebhookService.create_webhook_job(order_cycle, "order_cycle.opened") }
          .to enqueue_job(WebhookDeliveryJob).exactly(1).times
          .with("http://coordinator_owner_url", "order_cycle.opened", hash_including(data))
      end
    end

    context "coordinator owner doesn't have endpoint configured" do
      it "doesn't create webhook payload" do
        expect{ OrderCycleWebhookService.create_webhook_job(order_cycle, "order_cycle.opened") }
          .not_to enqueue_job(WebhookDeliveryJob)
      end
    end

    describe "distributors" do
      context "multiple distributors have owners with endpoint configured" do
        let(:order_cycle) {
          create(
            :simple_order_cycle,
            coordinator: coordinator,
            distributors: two_distributors,
          )
        }
        let(:two_distributors) {
          (1..2).map do |i|
            user = create(:user)
            user.webhook_endpoints.create!(url: "http://distributor#{i}_owner_url")
            create(:distributor_enterprise, owner: user)
          end
        }

        it "creates webhook payload for each order cycle distributor" do
          data = {
            coordinator_id: order_cycle.coordinator_id,
            coordinator_name: "Starship Enterprise",
          }

          expect{ OrderCycleWebhookService.create_webhook_job(order_cycle, "order_cycle.opened") }
            .to enqueue_job(WebhookDeliveryJob).with("http://distributor1_owner_url",
                                                     "order_cycle.opened", hash_including(data))
            .and enqueue_job(WebhookDeliveryJob).with("http://distributor2_owner_url",
                                                      "order_cycle.opened", hash_including(data))
        end
      end

      context "distributor owner is same user as coordinator owner" do
        let(:user) { coordinator.owner }
        let(:order_cycle) {
          create(
            :simple_order_cycle,
            coordinator: coordinator,
            distributors: [create(:distributor_enterprise, owner: user)],
          )
        }

        it "creates only one webhook payload for the user's endpoint" do
          user.webhook_endpoints.create! url: "http://coordinator_owner_url"

          expect{ OrderCycleWebhookService.create_webhook_job(order_cycle, "order_cycle.opened") }
            .to enqueue_job(WebhookDeliveryJob).with("http://coordinator_owner_url", any_args)
        end
      end
    end

    describe "suppliers" do
      context "supplier has owner with endpoint configured" do
        let(:order_cycle) {
          create(
            :simple_order_cycle,
            coordinator: coordinator,
            suppliers: [supplier],
          )
        }
        let(:supplier) {
          user = create(:user)
          user.webhook_endpoints.create!(url: "http://supplier_owner_url")
          create(:supplier_enterprise, owner: user)
        }

        it "doesn't create a webhook payload for supplier owner" do
          expect{ OrderCycleWebhookService.create_webhook_job(order_cycle, "order_cycle.opened") }
            .to_not enqueue_job(WebhookDeliveryJob).with("http://supplier_owner_url", any_args)
        end
      end
    end
  end

  context "without webhook subscribed to enterprise" do
    it "doesn't create webhook payload" do
      expect{ OrderCycleWebhookService.create_webhook_job(order_cycle, "order_cycle.opened") }
        .not_to enqueue_job(WebhookDeliveryJob)
    end
  end
end
