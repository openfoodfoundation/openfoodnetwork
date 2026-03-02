# frozen_string_literal: true

RSpec.describe Vine::VoucherRedeemerService, feature: :connected_apps do
  subject(:voucher_redeemer_service) { described_class.new(order: ) }

  let(:user) { order.user }
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:order) { create(:order_with_line_items, line_items_count: 1, distributor:, order_cycle:) }

  let(:vine_voucher) {
    create(:vine_voucher, code: 'some_code', enterprise: distributor,
                          amount: 50, external_voucher_id: voucher_id,
                          external_voucher_set_id: voucher_set_id )
  }
  let(:voucher_id) { "9d316d27-0dad-411a-8953-316a1aaf7742" }
  let(:voucher_set_id) { "9d314daa-0878-4b73-922d-698047640cf4" }
  let(:vine_api_service) { instance_double(Vine::ApiService) }

  before do
    allow(Vine::ApiService).to receive(:new).and_return(vine_api_service)
  end

  describe "#redeem" do
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
        # Order pre discount total is $10, so we expect to redeen 1000 cents
        expect(vine_api_service).to receive(:voucher_redemptions)
          .with(voucher_id, voucher_set_id, 1000)
          .and_return(mock_api_response(data:))

        voucher_redeemer_service.redeem
      end

      it "closes the linked assement" do
        allow(vine_api_service).to receive(:voucher_redemptions)
          .and_return(mock_api_response(data:))

        expect {
          voucher_redeemer_service.redeem
        }.to change { order.voucher_adjustments.first.state }.to("closed")
      end

      it "returns true" do
        allow(vine_api_service).to receive(:voucher_redemptions)
          .and_return(mock_api_response(data:))

        expect(voucher_redeemer_service.redeem).to be(true)
      end

      context "when redeeming fails" do
        let(:data) {
          {
            meta: { responseCode: 400, limit: 50, offset: 0, message: "Invalid merchant team." },
            data: []
          }.deep_stringify_keys
        }
        before do
          mock_api_exception(type: Faraday::BadRequestError, status: 400, body: data)
        end

        it "doesn't close the linked assement" do
          expect {
            voucher_redeemer_service.redeem
          }.not_to change { order.voucher_adjustments.first.state }
        end

        it "returns false" do
          expect(voucher_redeemer_service.redeem).to be(false)
        end

        it "adds an error message" do
          voucher_redeemer_service.redeem

          expect(voucher_redeemer_service.errors).to include(
            { redeeming_failed: "Redeeming the voucher failed" }
          )
        end
      end
    end

    context "when distributor is not connected to VINE" do
      before { add_voucher(vine_voucher) }

      it "returns false" do
        expect(voucher_redeemer_service.redeem).to be(false)
      end

      it "doesn't redeem the VINE API" do
        expect(vine_api_service).not_to receive(:voucher_redemptions)

        voucher_redeemer_service.redeem
      end

      it "doesn't close the linked assement" do
        expect {
          voucher_redeemer_service.redeem
        }.not_to change { order.voucher_adjustments.first.state }
      end
    end

    context "when there are no voucher added to the order" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }

      it "returns true" do
        expect(voucher_redeemer_service.redeem).to be(true)
      end

      it "doesn't redeem the VINE API" do
        expect(vine_api_service).not_to receive(:voucher_redemptions)

        voucher_redeemer_service.redeem
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
        expect(voucher_redeemer_service.redeem).to be(true)
      end

      it "doesn't redeem the VINE API" do
        expect(vine_api_service).not_to receive(:voucher_redemptions)

        voucher_redeemer_service.redeem
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
        mock_api_exception(type: Faraday::ConnectionFailed)
      end

      it "returns false" do
        expect(voucher_redeemer_service.redeem).to be(false)
      end

      it "adds an error message" do
        voucher_redeemer_service.redeem

        expect(voucher_redeemer_service.errors).to include(
          { vine_api: "There was an error communicating with the API, please try again later." }
        )
      end

      it "doesn't close the linked assement" do
        expect {
          voucher_redeemer_service.redeem
        }.not_to change { order.voucher_adjustments.first.state }
      end

      it "logs the error and notify bugsnag" do
        expect(Rails.logger).to receive(:error)
        expect(Bugsnag).to receive(:notify)

        voucher_redeemer_service.redeem
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

        mock_api_exception(type: Faraday::UnauthorizedError, status: 401, body: data)
      end

      it "returns false" do
        expect(voucher_redeemer_service.redeem).to be(false)
      end

      it "adds an error message" do
        voucher_redeemer_service.redeem

        expect(voucher_redeemer_service.errors).to include(
          { vine_api: "There was an error communicating with the API" }
        )
      end

      it "doesn't close the linked assement" do
        expect {
          voucher_redeemer_service.redeem
        }.not_to change { order.voucher_adjustments.first.state }
      end
    end
  end

  def add_voucher(voucher)
    voucher.create_adjustment(voucher.code, order)
    OrderManagement::Order::Updater.new(order).update_voucher
  end

  def mock_api_response(data: nil)
    mock_response = instance_double(Faraday::Response)
    if data.present?
      allow(mock_response).to receive(:body).and_return(data)
    end
    mock_response
  end

  def mock_api_exception(type: Faraday::Error, status: 503, body: nil)
    allow(vine_api_service).to receive(:voucher_redemptions).and_raise(type.new(nil,
                                                                                { status:,
                                                                                  body: }) )
  end
end
