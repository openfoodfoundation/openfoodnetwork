# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "CustomerAccountTransactions", swagger_doc: "v1.yaml" do
  let!(:enterprise) { create(:enterprise) }
  let(:customer) { create(:customer, enterprise:) }

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
            amount: "10.25",
            currency: "AUD",
            description: "API credit: Payment processed by POS",
            balance: "10.25",
          )

          transaction = CustomerAccountTransaction.find(json_response[:data][:attributes][:id])
          expect(transaction).not_to be_nil
          expect(transaction.created_by).to eq(enterprise.owner)
        end
      end

      response "422", "Unpermitted parameter" do
        let(:someone_else) { create(:user) }
        let(:customer_account_transaction) do
          {
            id: 101,
            customer_id: customer.id.to_s,
            amount: "10.25",
            created_by_id: someone_else.id.to_s,
          }
        end
        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(CustomerAccountTransaction.count).to eq 0
          expect(json_response[:errors][0][:detail]).to eq(
            "Parameters not allowed in this request: id, created_by_id"
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

      response "422", "Missing required parameter" do
        let(:customer_account_transaction) { { customer_id: customer.id.to_s } }
        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(json_response[:errors][0][:detail]).to eq(
            "Invalid resource. Please fix errors and try again."
          )
          expect(json_response[:meta][:validation_errors]).to eq ["Amount can't be blank"]
        end
      end

      response "404", "Invalid customer ID" do
        let(:customer_account_transaction) { { amount: "10.25" } }
        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(json_response[:errors][0][:detail]).to eq(
            "The resource you were looking for could not be found."
          )
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

      response "401", "Access forbidden" do
        # Customer belongs to enterprise that I don't have permission for
        let(:customer) { create(:customer, enterprise: create(:enterprise)) }

        let(:customer_account_transaction) do
          {
            customer_id: customer.id.to_s,
            amount: "10.25",
          }
        end

        run_test! do
          expect(customer.reload.credit_balance).to eq 0
        end
      end
    end

    describe "with a wrapped request body" do
      let(:params) do
        {
          customer_account_transaction: {
            customer_id: customer.id.to_s,
            amount: "10.25",
            description: "Payment processed by POS",
          }
        }
      end

      it "preserves the description nested in the wrapped body" do
        post "/api/v1/customer_account_transaction", params: params

        expect(response).to have_http_status(:created)
        expect(CustomerAccountTransaction.last.description)
          .to eq("API credit: Payment processed by POS")
      end
    end

    describe "concurrency", concurrency: true do
      let(:breakpoint) { Mutex.new }
      let(:params) do
        {
          customer_account_transaction: {
            customer_id: customer.id.to_s,
            amount: "10.00",
            description: "Concurent payment processed by POS",
          }
        }
      end
      let(:params2) do
        {
          customer_account_transaction: {
            customer_id: customer.id.to_s,
            amount: "15",
            description: "Concurent payment processed by POS",
          }
        }
      end

      it "processes one transaction at the time, ensure correct balance calculation" do
        breakpoint.lock
        breakpoint_reached_counter = 0

        # Set a breakpoint when save is calle. If two requests reach this breakpoint at the
        # same time, they are in a race condition but the the lock in the before_create callback
        # should ensure they are excuted one after the other.
        allow_any_instance_of(CustomerAccountTransaction).to receive(:save)
          .and_wrap_original do |method, *args|
            breakpoint_reached_counter += 1
            breakpoint.synchronize { nil }
            method.call(*args)
          end

        # Create two account transactions in parallel
        threads = [
          Thread.new {
            login_as enterprise.owner
            post "/api/v1/customer_account_transaction", params: params
          },
          Thread.new {
            login_as enterprise.owner
            post "/api/v1/customer_account_transaction", params: params2
          },
        ]

        # Wait for the first thread to reach the breakpoint:
        Timeout.timeout(1) do
          sleep 0.1 while breakpoint_reached_counter < 1
        end

        # Wait for the second thread to reach the breakpoint to confirm we have a race condition
        Timeout.timeout(1) do
          sleep 0.1 while breakpoint_reached_counter < 2
        end

        # Resume and complete both transaction creation:
        breakpoint.unlock
        threads.each(&:join)

        # There is no existing transaction, the thread are competing to create the first
        # transaction. So if the last transaction balance is anything but the sum of the amount
        # from both request, it means our datase locking is wrong.
        expect(CustomerAccountTransaction.last.balance).to eq(25)
      end
    end
  end
end
