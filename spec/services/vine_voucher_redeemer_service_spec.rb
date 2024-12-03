# frozen_string_literal: true

require "spec_helper"

RSpec.describe VineVoucherRedeemerService, feature: :connected_apps do
  subject(:voucher_redeemer_service) { described_class.new(order: ) }

  let(:user) { order.user }
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:order) { create(:order_with_line_items, line_items_count: 1, distributor:, order_cycle:) }

  let(:vine_voucher) {
    create(:voucher_flat_rate, voucher_type: "VINE", code: 'some_code', enterprise: distributor,
                               amount: 6, external_voucher_id: voucher_id,
                               external_voucher_set_id: voucher_set_id )
  }
  let(:voucher_id) { "9d316d27-0dad-411a-8953-316a1aaf7742" }
  let(:voucher_set_id) { "9d314daa-0878-4b73-922d-698047640cf4" }
  let(:vine_api_service) { instance_double(VineApiService) }

  before do
    allow(VineApiService).to receive(:new).and_return(vine_api_service)
  end

  describe "#call" do
    context "with a valid voucher" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }
      let(:data) {
        {
          meta: {
            responseCode: 200,
            limit: 50,
            offset: 0,
            message: "Redemption successful. This was a test redemption. Do NOT provide " \
                     "the person with goods or services."
          },
          data: {
            voucher_id: "9d316d27-0dad-411a-8953-316a1aaf7742",
            voucher_set_id: "9d314daa-0878-4b73-922d-698047640cf4",
            redeemed_by_user_id: 8,
            redeemed_by_team_id: 4,
            redeemed_amount: 1,
            is_test: 1,
            updated_at: "2024-10-21T03:07:09.000000Z",
            created_at: "2024-10-21T03:07:09.000000Z",
            id: 5
          }
        }.deep_stringify_keys
      }

      before { add_voucher(vine_voucher) }

      it "redeems the voucher with VINE" do
        expect(vine_api_service).to receive(:voucher_redemptions)
          .with(voucher_id, voucher_set_id, 600)
          .and_return(mock_api_response(success: true, data:))

        voucher_redeemer_service.call
      end

      it "closes the linked assement" do
        allow(vine_api_service).to receive(:voucher_redemptions)
          .and_return(mock_api_response(success: true, data:))

        expect {
          voucher_redeemer_service.call
        }.to change { order.voucher_adjustments.first.state }.to("closed")
      end

      it "returns true" do
        allow(vine_api_service).to receive(:voucher_redemptions)
          .and_return(mock_api_response(success: true, data:))

        expect(voucher_redeemer_service.call).to be(true)
      end

      context "when redeeming fails" do
        let(:data) {
          {
            meta: { responseCode: 400, limit: 50, offset: 0, message: "Invalid merchant team." },
            data: []
          }.deep_stringify_keys
        }
        before do
          allow(vine_api_service).to receive(:voucher_redemptions)
            .and_return(mock_api_response(success: false, data:, status: 400))
        end

        it "doesn't close the linked assement" do
          expect {
            voucher_redeemer_service.call
          }.not_to change { order.voucher_adjustments.first.state }
        end

        it "returns false" do
          expect(voucher_redeemer_service.call).to be(false)
        end

        it "adds an error message" do
          voucher_redeemer_service.call

          expect(voucher_redeemer_service.errors).to include(
            { redeeming_failed: "Redeeming the voucher failed" }
          )
        end
      end
    end

    context "when distributor is not connected to VINE" do
      before { add_voucher(vine_voucher) }

      it "returns false" do
        expect(voucher_redeemer_service.call).to be(false)
      end

      it "doesn't call the VINE API" do
        expect(vine_api_service).not_to receive(:voucher_redemptions)

        voucher_redeemer_service.call
      end

      it "adds an error message" do
        voucher_redeemer_service.call

        expect(voucher_redeemer_service.errors).to include(
          { vine_settings: "No Vine api settings for the given enterprise" }
        )
      end

      it "doesn't close the linked assement" do
        expect {
          voucher_redeemer_service.call
        }.not_to change { order.voucher_adjustments.first.state }
      end
    end

    # TODO should we set an error or just do nothing ?
    context "when there are no voucher added to the order" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }

      it "returns true" do
        expect(voucher_redeemer_service.call).to be(true)
      end

      it "doesn't call the VINE API" do
        expect(vine_api_service).not_to receive(:voucher_redemptions)

        voucher_redeemer_service.call
      end
    end

    context "with a non vine voucher" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }
      let(:voucher) { create(:voucher_flat_rate, enterprise: distributor) }

      before { add_voucher(voucher) }

      it "returns true" do
        expect(voucher_redeemer_service.call).to be(true)
      end

      it "doesn't call the VINE API" do
        expect(vine_api_service).not_to receive(:voucher_redemptions)

        voucher_redeemer_service.call
      end
    end

    context "when there is an API error" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }

      before do
        add_voucher(vine_voucher)
        allow(vine_api_service).to receive(:voucher_redemptions).and_raise(Faraday::Error)
      end

      it "returns false" do
        expect(voucher_redeemer_service.call).to be(false)
      end

      it "adds an error message" do
        voucher_redeemer_service.call

        expect(voucher_redeemer_service.errors).to include(
          { vine_api: "There was an error communicating with the API" }
        )
      end

      it "doesn't close the linked assement" do
        expect {
          voucher_redeemer_service.call
        }.not_to change { order.voucher_adjustments.first.state }
      end

      it "logs the error and notify bugsnag" do
        expect(Rails.logger).to receive(:error)
        expect(Bugsnag).to receive(:notify)

        voucher_redeemer_service.call
      end
    end

    context "when there is an API authentication error" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }
      let(:data) {
        {
          meta: { numRecords: 0, totalRows: 0, responseCode: 401,
                  message: "Incorrect authorization signature." },
          data: []
        }.deep_stringify_keys
      }

      before do
        add_voucher(vine_voucher)

        allow(vine_api_service).to receive(:voucher_redemptions).and_return(
          mock_api_response(success: false, status: 401, data: )
        )
      end

      it "returns false" do
        expect(voucher_redeemer_service.call).to be(false)
      end

      it "adds an error message" do
        voucher_redeemer_service.call

        expect(voucher_redeemer_service.errors).to include(
          { vine_api: "There was an error communicating with the API" }
        )
      end

      it "doesn't close the linked assement" do
        expect {
          voucher_redeemer_service.call
        }.not_to change { order.voucher_adjustments.first.state }
      end
    end
  end

  def add_voucher(voucher)
    voucher.create_adjustment(voucher.code, order)
    VoucherAdjustmentsService.new(order).update
    order.update_totals_and_states
  end

  def mock_api_response(success:, data: nil, status: 200)
    mock_response = instance_double(Faraday::Response)
    allow(mock_response).to receive(:success?).and_return(success)
    allow(mock_response).to receive(:status).and_return(status)
    if data.present?
      allow(mock_response).to receive(:body).and_return(data)
    end
    mock_response
  end
end
