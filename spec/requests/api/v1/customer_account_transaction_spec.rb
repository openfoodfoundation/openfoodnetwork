# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "CustomerAccountTransactions", swagger_doc: "v1.yaml", feature: :api_v1 do
  let!(:enterprise) { create(:enterprise) }
  let(:payment_method) {
    create(
      :payment_method,
      name: CustomerAccountTransaction::DEFAULT_PAYMENT_METHOD_NAME,
      distributors: [enterprise]
    )
  }
  let(:customer) { create(:customer) }

  before do
    login_as enterprise.owner
  end

  path "/api/v1/customer_account_transaction" do
    post "Create customer transaction" do
      tags "Customer account transaction"
      consumes "application/json"
      produces "application/json"

      parameter name: :customer_account_transaction, in: :body, schema: {
        type: :object,
        properties: CustomerAccountTransactionSchema.writable_attributes,
        required: CustomerAccountTransactionSchema.required_attributes
      }

      response "201", "Customer transaction created" do
        let(:customer_account_transaction) do
          {
            customer_id: customer.id.to_s,
            amount: "10.25",
            description: "Payment processed by POS"
          }
        end
        schema '$ref': "#/components/schemas/customer_account_transaction"

        run_test! do
          expect(json_response[:data][:attributes]).to include(
            customer_id: customer.id,
            payment_method_id: payment_method.id,
            amount: "10.25",
            currency: "AUD",
            description: "Payment processed by POS",
            balance: "10.25",
          )

          transaction = CustomerAccountTransaction.find(json_response[:data][:attributes][:id])
          expect(transaction).not_to be_nil
        end
      end

      response "422", "Unpermitted parameter" do
        let(:customer_account_transaction) do
          {
            id: 101,
            customer_id: customer.id.to_s,
            amount: "10.25",
          }
        end
        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(json_response[:errors][0][:detail]).to eq(
            "Parameters not allowed in this request: id"
          )
        end
      end

      response "422", "Unprocessable entity" do
        let(:customer_account_transaction) { {} }
        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(json_response[:errors][0][:detail]).to eq(
            "A required parameter is missing or empty: customer_account_transaction"
          )
          expect(json_response[:meta]).to eq nil
        end
      end

      response "422", "Invalid resource" do
        let(:customer_account_transaction) { { amount: "10.25" } }
        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(json_response[:errors][0][:detail]).to eq(
            "Invalid resource. Please fix errors and try again."
          )
          expect(json_response[:meta][:validation_errors]).to eq ["Customer must exist"]
        end
      end

      response "401", "Unauthorized" do
        before { login_as nil }

        let(:customer_account_transaction) do
          {
            customer_id: customer.id.to_s,
            amount: "10.25",
          }
        end

        run_test!
      end
    end
  end
end
