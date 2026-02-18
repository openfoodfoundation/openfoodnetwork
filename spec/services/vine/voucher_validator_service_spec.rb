# frozen_string_literal: true

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
            id: vine_voucher_id,
            voucher_short_code: voucher_code,
            voucher_set_id: vine_voucher_set_id,
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
      let(:vine_voucher_id) { "9d2437c8-4559-4dda-802e-8d9c642a0c1d" }
      let(:vine_voucher_set_id) { "9d24349c-1fe8-4090-988b-d7355ed32559" }

      it "verifies the voucher with VINE API" do
        expect(vine_api_service).to receive(:voucher_validation).and_return(
          mock_api_response(data:)
        )

        validate_voucher_service.validate
      end

      it "creates a new VINE voucher" do
        allow(vine_api_service).to receive(:voucher_validation).and_return(mock_api_response(data:))

        vine_voucher = validate_voucher_service.validate

        expect(vine_voucher).not_to be_nil
        expect(vine_voucher).to be_a(Vouchers::Vine)
        expect(vine_voucher.code).to eq(voucher_code)
        expect(vine_voucher.amount).to eq(5.00)
        expect(vine_voucher.external_voucher_id).to eq(vine_voucher_id)
        expect(vine_voucher.external_voucher_set_id).to eq(vine_voucher_set_id)
      end

      context "when the VINE voucher has already been used by another enterprise" do
        let(:data) {
          {
            meta: { responseCode: 200, limit: 50, offset: 0, message: "" },
            data: {
              id: vine_voucher_id,
              voucher_short_code: voucher_code,
              voucher_set_id: vine_voucher_set_id,
              is_test: 1,
              voucher_value_original: 500,
              voucher_value_remaining: 250,
              num_voucher_redemptions: 0,
              last_redemption_at: "null",
              created_at: "2024-10-01T13:20:02.000000Z",
              updated_at: "2024-10-01T13:20:02.000000Z",
              deleted_at: "null"
            }
          }.deep_stringify_keys
        }

        it "creates a new voucher" do
          existing_voucher = create(:vine_voucher, enterprise: create(:enterprise),
                                                   code: voucher_code,
                                                   external_voucher_id: vine_voucher_id,
                                                   external_voucher_set_id: vine_voucher_set_id)
          allow(vine_api_service).to receive(:voucher_validation)
            .and_return(mock_api_response(data:))

          vine_voucher = validate_voucher_service.validate

          expect(vine_voucher.id).not_to eq(existing_voucher.id)
          expect(vine_voucher.enterprise).to eq(distributor)
          expect(vine_voucher.code).to eq(voucher_code)
          expect(vine_voucher.amount).to eq(2.50)
          expect(vine_voucher).to be_a(Vouchers::Vine)
          expect(vine_voucher.external_voucher_id).to eq(vine_voucher_id)
          expect(vine_voucher.external_voucher_set_id).to eq(vine_voucher_set_id)
        end
      end

      context "with a recycled code" do
        let(:data) {
          {
            meta: { responseCode: 200, limit: 50, offset: 0, message: "" },
            data: {
              id: new_vine_voucher_id,
              voucher_short_code: voucher_code,
              voucher_set_id: new_vine_voucher_set_id,
              is_test: 1,
              voucher_value_original: 500,
              voucher_value_remaining: 140,
              num_voucher_redemptions: 0,
              last_redemption_at: "null",
              created_at: "2024-10-01T13:20:02.000000Z",
              updated_at: "2024-10-01T13:20:02.000000Z",
              deleted_at: "null"
            }
          }.deep_stringify_keys
        }
        let(:new_vine_voucher_id) { "9d2437c8-4559-4dda-802e-8d9c642a0c5e" }
        let(:new_vine_voucher_set_id) { "9d24349c-1fe8-4090-988b-d7355ed32590" }

        it "creates a new voucher" do
          existing_voucher = create(:vine_voucher, enterprise: distributor, code: voucher_code,
                                                   external_voucher_id: vine_voucher_id,
                                                   external_voucher_set_id: vine_voucher_set_id)
          allow(vine_api_service).to receive(:voucher_validation)
            .and_return(mock_api_response(data:))

          vine_voucher = validate_voucher_service.validate

          expect(vine_voucher.id).not_to eq(existing_voucher.id)
          expect(vine_voucher.enterprise).to eq(distributor)
          expect(vine_voucher.code).to eq(voucher_code)
          expect(vine_voucher.amount).to eq(1.40)
          expect(vine_voucher).to be_a(Vouchers::Vine)
          expect(vine_voucher.external_voucher_id).to eq(new_vine_voucher_id)
          expect(vine_voucher.external_voucher_set_id).to eq(new_vine_voucher_set_id)
        end
      end
    end

    context "when distributor is not connected to VINE" do
      it "returns nil" do
        expect_validate_to_be_nil
      end

      it "doesn't call the VINE API" do
        expect(vine_api_service).not_to receive(:voucher_validation)

        validate_voucher_service.validate
      end

      it "doesn't creates a new VINE voucher" do
        expect_voucher_count_not_to_change
      end
    end

    context "when there is an API error" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234567", secret: "my_secret" }
        )
      }

      before do
        mock_api_exception(type: Faraday::ConnectionFailed)
      end

      it "returns nil" do
        expect_validate_to_be_nil
      end

      it "adds an error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { vine_api: "There was an error communicating with the API, please try again later." }
        )
      end

      it "doesn't creates a new VINE voucher" do
        expect_voucher_count_not_to_change
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
        mock_api_exception(type: Faraday::UnauthorizedError, status: 401, body: data)
      end

      it "returns nil" do
        expect_validate_to_be_nil
      end

      it "adds an error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { vine_api: "There was an error communicating with the API, please try again later." }
        )
      end

      it "doesn't creates a new VINE voucher" do
        expect_voucher_count_not_to_change
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
        mock_api_exception(type: Faraday::ResourceNotFound, status: 404, body: data)
      end

      it "returns nil" do
        expect_validate_to_be_nil
      end

      it "adds an error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { not_found_voucher: "Sorry, we couldn't find that voucher, please check the code." }
        )
      end

      it "doesn't creates a new VINE voucher" do
        expect_voucher_count_not_to_change
      end
    end

    context "when the voucher is an invalid voucher" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234568", secret: "my_secret" }
        )
      }
      # Faraday returns un-parsed json
      let(:data) {
        {
          meta: { responseCode: 400, limit: 50, offset: 0, message: "Invalid merchant team." },
          data: []
        }.to_json
      }

      before do
        mock_api_exception(type: Faraday::BadRequestError, status: 400, body: data)
      end

      it "returns nil" do
        expect_validate_to_be_nil
      end

      it "adds a general error message" do
        validate_voucher_service.validate

        expect(validate_voucher_service.errors).to include(
          { invalid_voucher: "The voucher is not valid" }
        )
      end

      context "it is expired" do
        let(:data) {
          {
            meta: { responseCode: 400, limit: 50, offset: 0, message: "This voucher has expired." },
            data: []
          }.to_json
        }

        it "adds a specific error message" do
          validate_voucher_service.validate

          expect(validate_voucher_service.errors).to include(
            { invalid_voucher: "The voucher has expired" }
          )
        end
      end

      it "doesn't creates a new VINE voucher" do
        expect_voucher_count_not_to_change
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
          mock_api_response(data: )
        )
      end

      it "returns an invalid voucher" do
        voucher = validate_voucher_service.validate
        expect(voucher).not_to be_valid
        expect(voucher.errors[:amount]).to include "must be greater than 0"
      end
    end

    context "with an existing voucher" do
      let!(:vine_connected_app) {
        ConnectedApps::Vine.create(
          enterprise: distributor, data: { api_key: "1234567", secret: "my_secret" }
        )
      }
      let!(:voucher) {
        create(:vine_voucher, enterprise: distributor, code: voucher_code, amount: 500,
                              external_voucher_id: vine_voucher_id,
                              external_voucher_set_id: "9d24349c-1fe8-4090-988b-d7355ed32559")
      }
      let(:vine_voucher_id) { "9d2437c8-4559-4dda-802e-8d9c642a0c1d" }

      let(:data) {
        {
          meta: { responseCode: 200, limit: 50, offset: 0, message: "" },
          data: {
            id: vine_voucher_id,
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
          mock_api_response(data: )
        )
      end

      it "verify the voucher with VINE API" do
        expect(vine_api_service).to receive(:voucher_validation).and_return(
          mock_api_response(data: )
        )

        validate_voucher_service.validate
      end

      it "updates the VINE voucher" do
        vine_voucher = validate_voucher_service.validate

        expect(vine_voucher.id).to eq(voucher.id)
        expect(vine_voucher.reload.amount).to eq(2.50)
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

      context "it is expired" do
        let(:data) {
          {
            meta: { responseCode: 400, limit: 50, offset: 0, message: "This voucher has expired." },
            data: []
          }.to_json
        }

        it "adds a specific error message" do
          mock_api_exception(type: Faraday::BadRequestError, status: 409, body: data)

          validate_voucher_service.validate

          expect(validate_voucher_service.errors).to include(
            { invalid_voucher: "The voucher has expired" }
          )
        end
      end
    end
  end

  def expect_validate_to_be_nil
    expect(validate_voucher_service.validate).to be_nil
  end

  def expect_voucher_count_not_to_change
    expect { validate_voucher_service.validate }.not_to change { Voucher.count }
  end

  def mock_api_response(data: nil)
    mock_response = instance_double(Faraday::Response)
    if data.present?
      allow(mock_response).to receive(:body).and_return(data)
    end
    mock_response
  end

  def mock_api_exception(type: Faraday::Error, status: 503, body: nil)
    allow(vine_api_service).to receive(:voucher_validation).and_raise(type.new(nil,
                                                                               { status:, body: }) )
  end
end
