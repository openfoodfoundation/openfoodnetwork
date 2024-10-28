# frozen_string_literal: true

require "spec_helper"

RSpec.describe Vine::VoucherValidatorService, feature: :connected_apps do
  subject(:validate_voucher_service) { described_class.new(voucher_code:, enterprise: distributor) }

  let(:voucher_code) { "good_code" }
  let(:distributor) { create(:distributor_enterprise) }
  let(:vine_api_service) { instance_double(Vine::ApiService) }

  before do
    allow(Vine::ApiService).to receive(:new).and_return(vine_api_service)
  end

  describe "#validate" do
    context "with a valid voucher" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }
      let(:data) {
        {
          meta: { responseCode: 200, limit: 50, offset: 0, message: "" },
          data: {
            id: "9d2437c8-4559-4dda-802e-8d9c642a0c1d",
            voucher_short_code: voucher_code,
            voucher_set_id: "9d24349c-1fe8-4090-988b-d7355ed32559",
            is_test: 1,
            voucher_value_original: 500,
            voucher_value_remaining: 500,
            num_voucher_redemptions: 0,
            last_redemption_at: "null",
            created_at: "2024-10-01T13:20:02.000000Z",
            updated_at: "2024-10-01T13:20:02.000000Z",
            deleted_at: "null"
          }
        }.deep_stringify_keys
      }

      it "verifies the voucher with VINE API" do
        expect(vine_api_service).to receive(:voucher_validation)
          .and_return(mock_api_response( success: true, data:))

        validate_voucher_service.validate
      end

      it "creates a new VINE voucher" do
        allow(vine_api_service).to receive(:voucher_validation)
          .and_return(mock_api_response( success: true, data:))

        vine_voucher = validate_voucher_service.validate

        expect(vine_voucher).not_to be_nil
        expect(vine_voucher.code).to eq(voucher_code)
        expect(vine_voucher.amount).to eq(5.00)
        expect(vine_voucher.voucher_type).to eq("VINE")
        expect(vine_voucher.external_voucher_id).to eq("9d2437c8-4559-4dda-802e-8d9c642a0c1d")
        expect(vine_voucher.external_voucher_set_id).to eq(
          "9d24349c-1fe8-4090-988b-d7355ed32559"
        )
      end
    end

    context "when distributor is not connected to VINE" do
      it "returns nil" do
        expect(validate_voucher_service.validate).to be_nil
      end

      it "doesn't call the VINE API" do
        expect(vine_api_service).not_to receive(:voucher_validation)

        validate_voucher_service.validate
      end

      it "adds an error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { vine_settings: "No Vine api settings for the given enterprise" }
        )
      end

      it "doesn't creates a new VINE voucher" do
        expect { validate_voucher_service.validate }.not_to change { Voucher.count }
      end
    end

    context "when there is an API error" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234567", secret: "my_secret" }
        )
      }

      before do
        allow(vine_api_service).to receive(:voucher_validation).and_raise(Faraday::Error)
      end

      it "returns nil" do
        expect(validate_voucher_service.validate).to be_nil
      end

      it "adds an error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { vine_api: "There was an error communicating with the API" }
        )
      end

      it "doesn't creates a new VINE voucher" do
        expect { validate_voucher_service.validate }.not_to change { Voucher.count }
      end

      it "logs the error and notify bugsnag" do
        expect(Rails.logger).to receive(:error)
        expect(Bugsnag).to receive(:notify)

        validate_voucher_service.validate
      end
    end

    context "when there is an API authentication error" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234567", secret: "my_secret" }
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
        allow(vine_api_service).to receive(:voucher_validation).and_return(
          mock_api_response(success: false, status: 401, data: )
        )
      end

      it "returns nil" do
        expect(validate_voucher_service.validate).to be_nil
      end

      it "adds an error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { vine_api: "There was an error communicating with the API" }
        )
      end

      it "doesn't creates a new VINE voucher" do
        expect { validate_voucher_service.validate }.not_to change { Voucher.count }
      end
    end

    context "when the voucher doesn't exist" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }
      let(:data) {
        {
          meta: { responseCode: 404, limit: 50, offset: 0, message: "Not found" },
          data: []
        }.deep_stringify_keys
      }

      before do
        allow(vine_api_service).to receive(:voucher_validation).and_return(
          mock_api_response(success: false, status: 404, data: )
        )
      end

      it "returns nil" do
        expect(validate_voucher_service.validate).to be_nil
      end

      it "adds an error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { not_found_voucher: "The voucher doesn't exist" }
        )
      end

      it "doesn't creates a new VINE voucher" do
        expect { validate_voucher_service.validate }.not_to change { Voucher.count }
      end
    end

    context "when the voucher is an invalid voucher" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }
      let(:data) {
        {
          meta: { responseCode: 400, limit: 50, offset: 0, message: "Invalid merchant team." },
          data: []
        }.deep_stringify_keys
      }

      before do
        allow(vine_api_service).to receive(:voucher_validation).and_return(
          mock_api_response(success: false, status: 400, data: )
        )
      end

      it "returns nil" do
        expect(validate_voucher_service.validate).to be_nil
      end

      it "adds an error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { invalid_voucher: "The voucher is not valid" }
        )
      end

      it "doesn't creates a new VINE voucher" do
        expect { validate_voucher_service.validate }.not_to change { Voucher.count }
      end
    end

    context "when creating a new voucher fails" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }
      let(:data) {
        {
          meta: { responseCode: 200, limit: 50, offset: 0, message: "" },
          data: {
            id: "9d2437c8-4559-4dda-802e-8d9c642a0c1d",
            voucher_short_code: voucher_code,
            voucher_set_id: "9d24349c-1fe8-4090-988b-d7355ed32559",
            is_test: 1,
            voucher_value_original: 500,
            voucher_value_remaining: '',
            num_voucher_redemptions: 0,
            last_redemption_at: "null",
            created_at: "2024-10-01T13:20:02.000000Z",
            updated_at: "2024-10-01T13:20:02.000000Z",
            deleted_at: "null"
          }
        }.deep_stringify_keys
      }

      before do
        allow(vine_api_service).to receive(:voucher_validation).and_return(
          mock_api_response(success: true, status: 200, data: )
        )
      end

      it "returns an invalid voucher" do
        voucher = validate_voucher_service.validate
        expect(voucher).not_to be_valid
      end
    end

    context "with an existing voucher" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234567", secret: "my_secret" }
        )
      }
      let!(:voucher) {
        create(:voucher_flat_rate, enterprise: distributor, code: voucher_code,
                                   amount: 500, voucher_type: "VINE" )
      }

      let(:data) {
        {
          meta: { responseCode: 200, limit: 50, offset: 0, message: "" },
          data: {
            id: "9d2437c8-4559-4dda-802e-8d9c642a0c1d",
            voucher_short_code: voucher_code,
            voucher_set_id: "9d24349c-1fe8-4090-988b-d7355ed32559",
            is_test: 1,
            voucher_value_original: 500,
            voucher_value_remaining: 250,
            num_voucher_redemptions: 1,
            last_redemption_at: "2024-10-05T13:20:02.000000Z",
            created_at: "2024-10-01T13:20:02.000000Z",
            updated_at: "2024-10-01T13:20:02.000000Z",
            deleted_at: "null"
          }
        }.deep_stringify_keys
      }

      before do
        allow(vine_api_service).to receive(:voucher_validation).and_return(
          mock_api_response(success: true, status: 200, data: )
        )
      end

      it "verify the voucher with VINE API" do
        expect(vine_api_service).to receive(:voucher_validation).and_return(
          mock_api_response(success: true, status: 200, data: )
        )

        validate_voucher_service.validate
      end

      it "updates the VINE voucher" do
        vine_voucher = validate_voucher_service.validate

        expect(vine_voucher.id).to eq(voucher.id)
        expect(vine_voucher.amount).to eq(2.50)
      end

      context "when updating the voucher fails" do
        let(:data) {
          {
            meta: { responseCode: 200, limit: 50, offset: 0, message: "" },
            data: {
              id: "9d2437c8-4559-4dda-802e-8d9c642a0c1d",
              voucher_short_code: voucher_code,
              voucher_set_id: "9d24349c-1fe8-4090-988b-d7355ed32559",
              is_test: 1,
              voucher_value_original: 500,
              voucher_value_remaining: '',
              num_voucher_redemptions: 0,
              last_redemption_at: "null",
              created_at: "2024-10-01T13:20:02.000000Z",
              updated_at: "2024-10-01T13:20:02.000000Z",
              deleted_at: "null"
            }
          }.deep_stringify_keys
        }

        it "returns an invalid voucher" do
          vine_voucher = validate_voucher_service.validate
          expect(vine_voucher).not_to be_valid
        end

        it "doesn't update existing voucher" do
          expect {
            validate_voucher_service.validate
          }.not_to change { voucher.reload.amount }
        end
      end
    end
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
