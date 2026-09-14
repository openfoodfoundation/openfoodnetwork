# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::CustomerAccountTransactionController do
  let(:enterprise_user) { create(:user, enterprises: [enterprise]) }
  let(:enterprise) { create(:enterprise) }
  let(:customer) { create(:customer, enterprise:) }

  before do
    login_as enterprise_user
  end

  describe "GET /admin/customers/:customer_id/customer_account_transaction" do
    it "returns a list of customer transactions" do
      create(:customer_account_transaction, customer:)

      get admin_customer_customer_account_transaction_index_path(customer),
          params: { format: :turbo_stream }

      expect(response).to render_template("admin/customer_account_transaction/index")
    end

    context "with a non authorized customer" do
      let(:customer) { create(:customer) }

      it "returns unauthorized" do
        create(:customer_account_transaction, customer:)

        get admin_customer_customer_account_transaction_index_path(customer),
            params: { format: :turbo_stream }

        expect(response).to redirect_to(unauthorized_path)
      end
    end
  end

  describe "GET /admin/customers/:customer_id/customer_account_transaction/new" do
    it "renders the add credit form" do
      get new_admin_customer_customer_account_transaction_path(customer),
          params: { format: :turbo_stream }

      expect(response).to render_template("admin/customer_account_transaction/new")
    end

    context "with a non authorized customer" do
      let(:customer) { create(:customer) }

      it "returns unauthorized" do
        get new_admin_customer_customer_account_transaction_path(customer),
            params: { format: :turbo_stream }

        expect(response).to redirect_to(unauthorized_path)
      end
    end
  end

  describe "POST /admin/customers/:customer_id/customer_account_transaction" do
    let(:params) do
      {
        customer_account_transaction: { amount: "10.00", description: "Prepaid top-up" },
        format: :turbo_stream
      }
    end

    it "creates a credit transaction and updates the balance" do
      expect {
        post admin_customer_customer_account_transaction_index_path(customer), params:
      }.to change { customer.customer_account_transactions.count }.by(1)

      transaction = customer.customer_account_transactions.last
      expect(transaction.amount).to eq(10.00)
      expect(transaction.description).to eq("Prepaid top-up")
      expect(transaction.created_by).to eq(enterprise_user)
      expect(response).to render_template("admin/customer_account_transaction/index")
    end

    context "with a non-positive amount" do
      let(:params) do
        {
          customer_account_transaction: { amount: "0", description: "Prepaid top-up" },
          format: :turbo_stream
        }
      end

      it "does not create a transaction and re-renders the form with an error message" do
        expect {
          post admin_customer_customer_account_transaction_index_path(customer), params:
        }.not_to change { customer.customer_account_transactions.count }

        expect(response).to render_template("admin/customer_account_transaction/new")
        expect(response.body).to include("must be greater than 0")
      end
    end

    context "with a negative amount" do
      let(:params) do
        {
          customer_account_transaction: { amount: "-5", description: "Prepaid top-up" },
          format: :turbo_stream
        }
      end

      it "does not create a transaction and re-renders the form with an error message" do
        expect {
          post admin_customer_customer_account_transaction_index_path(customer), params:
        }.not_to change { customer.customer_account_transactions.count }

        expect(response).to render_template("admin/customer_account_transaction/new")
        expect(response.body).to include("must be greater than 0")
      end
    end

    context "with an amount above the allowed maximum" do
      let(:params) do
        {
          customer_account_transaction: { amount: "999999999999", description: "Prepaid top-up" },
          format: :turbo_stream
        }
      end

      it "rejects the amount instead of raising, and re-renders the form" do
        expect {
          post admin_customer_customer_account_transaction_index_path(customer), params:
        }.not_to change { customer.customer_account_transactions.count }

        expect(response).to render_template("admin/customer_account_transaction/new")
        expect(response.body).to include("must be less than 100000000")
      end
    end

    context "with a blank description" do
      let(:params) do
        {
          customer_account_transaction: { amount: "10.00", description: "" },
          format: :turbo_stream
        }
      end

      it "does not create a transaction and re-renders the form with an error message" do
        expect {
          post admin_customer_customer_account_transaction_index_path(customer), params:
        }.not_to change { customer.customer_account_transactions.count }

        expect(response).to render_template("admin/customer_account_transaction/new")
        expect(response.body).to include("can&#39;t be blank")
      end
    end

    context "with a non authorized customer" do
      let(:customer) { create(:customer) }

      it "returns unauthorized" do
        post(admin_customer_customer_account_transaction_index_path(customer), params:)

        expect(response).to redirect_to(unauthorized_path)
      end
    end
  end
end
