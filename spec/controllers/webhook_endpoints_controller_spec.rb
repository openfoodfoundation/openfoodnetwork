# frozen_string_literal: false

require 'open_food_network/order_cycle_permissions'

RSpec.describe WebhookEndpointsController do
  let(:user) { create(:admin_user) }

  before { allow(controller).to receive(:spree_current_user) { user } }

  describe "#create" do
    it "creates a webhook_endpoint" do
      expect {
        spree_post :create, { url: "https://url", webhook_type: "order_cycle_opened" }
      }.to change {
        user.webhook_endpoints.count
      }.by(1)

      expect(flash[:success]).to be_present
      expect(flash[:error]).to be_blank
      webhook = user.webhook_endpoints.first
      expect(webhook.url).to eq "https://url"
      expect(webhook.webhook_type).to eq "order_cycle_opened"
    end

    it "shows error if parameters not specified" do
      expect {
        spree_post :create, { url: "" }
      }.not_to change {
        user.webhook_endpoints.count
      }

      expect(flash[:success]).to be_blank
      expect(flash[:error]).to be_present
    end

    it "redirects back to referrer" do
      spree_post :create, { url: "https://url", webhook_type: "order_cycle_opened" }

      expect(response).to redirect_to "/account#/developer_settings"
    end
  end

  describe "#destroy" do
    let!(:webhook_endpoint) {
      user.webhook_endpoints.create(url: "https://url", webhook_type: "order_cycle_opened")
    }

    it "destroys a webhook_endpoint" do
      webhook_endpoint2 = user.webhook_endpoints.create!(url: "https://url2",
                                                         webhook_type: "order_cycle_opened")

      expect {
        spree_delete :destroy, { id: webhook_endpoint.id }
      }.to change {
        user.webhook_endpoints.count
      }.by(-1)

      expect(flash[:success]).to be_present
      expect(flash[:error]).to be_blank

      expect{ webhook_endpoint.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(webhook_endpoint2.reload).to be_present
    end

    it "redirects back to developer settings tab" do
      spree_delete :destroy, id: webhook_endpoint.id

      expect(response).to redirect_to "/account#/developer_settings"
    end
  end

  describe "#test" do
    let(:webhook_endpoint) {
      user.webhook_endpoints.create(url: "https://url", webhook_type: "payment_status_changed" )
    }

    subject { spree_post :test, id: webhook_endpoint.id, format: :turbo_stream }

    it "enqueus a webhook job" do
      expect { subject }.to enqueue_job(WebhookDeliveryJob).exactly(1).times
        .with("https://url", "payment.completed", any_args)
    end

    it "shows a success mesage" do
      subject

      expect(flash[:success]).to eq "Some test data will be sent to the webhook url"
    end

    context "with an order payment due endpoint" do
      let(:webhook_endpoint) {
        user.webhook_endpoints.create(url: "https://url", webhook_type: "order_payment_due")
      }

      it "enqueues a webhook job with the order payment due test data" do
        expect { subject }.to enqueue_job(WebhookDeliveryJob).exactly(1).times
          .with("https://url", "order.payment_due", any_args)
      end

      it "describes the payload an integration will receive" do
        payload = Orders::WebhookPayload.test_data.to_hash

        expect(payload[:order]).to include("number", "email", "outstanding_balance")
        expect(payload[:payment_method].keys).to contain_exactly("id", "name")
      end
    end

    context "with a webhook type we have no test data for" do
      let(:webhook_endpoint) {
        user.webhook_endpoints.create(url: "https://url", webhook_type: "order_cycle_opened")
      }

      it "does not enqueue a webhook job" do
        expect { subject }.not_to enqueue_job(WebhookDeliveryJob)
      end

      it "shows an error message" do
        subject

        expect(flash[:error]).to eq "There is no test data for this webhook type"
      end
    end
  end
end
