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

    it "does not show the negative amount hint to a hub manager" do
      get new_admin_customer_customer_account_transaction_path(customer),
          params: { format: :turbo_stream }

      expect(response.body).not_to include("enter a negative amount")
    end

    context "as a super admin" do
      before { login_as create(:admin_user) }

      it "shows the negative amount hint" do
        get new_admin_customer_customer_account_transaction_path(customer),
            params: { format: :turbo_stream }

        expect(response.body).to include("enter a negative amount to deduct credit")
      end
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

    context "as a super admin" do
      let(:admin_user) { create(:admin_user) }
      let(:params) do
        {
          customer_account_transaction: { amount: "-5", description: "Correction" },
          format: :turbo_stream
        }
      end

      let(:existing_credit) { 20 }

      before do
        login_as admin_user
        create(:customer_account_transaction, customer:, amount: existing_credit)
      end

      it "allows a negative amount to deduct credit" do
        expect {
          post admin_customer_customer_account_transaction_index_path(customer), params:
        }.to change { customer.customer_account_transactions.count }.by(1)

        transaction = customer.customer_account_transactions.order(:id).last
        expect(transaction.amount).to eq(-5)
        expect(transaction.balance).to eq(15)
        expect(transaction.created_by).to eq(admin_user)
        expect(response).to render_template("admin/customer_account_transaction/index")
      end

      context "with a zero amount" do
        let(:params) do
          {
            customer_account_transaction: { amount: "0", description: "Correction" },
            format: :turbo_stream
          }
        end

        it "does not create a transaction and re-renders the form with an error message" do
          expect {
            post admin_customer_customer_account_transaction_index_path(customer), params:
          }.not_to change { customer.customer_account_transactions.count }

          expect(response).to render_template("admin/customer_account_transaction/new")
          expect(response.body).to include("must be other than 0")
        end
      end

      context "with a deduction equal to the available credit" do
        let(:params) do
          {
            customer_account_transaction: { amount: "-20", description: "Correction" },
            format: :turbo_stream
          }
        end

        it "brings the balance down to zero" do
          post(admin_customer_customer_account_transaction_index_path(customer), params:)

          expect(customer.credit_balance).to eq(0)
          expect(response).to render_template("admin/customer_account_transaction/index")
        end
      end

      context "with a deduction larger than the available credit" do
        let(:params) do
          {
            customer_account_transaction: { amount: "-20.01", description: "Correction" },
            format: :turbo_stream
          }
        end

        it "does not create a transaction and re-renders the form with an error message" do
          expect {
            post admin_customer_customer_account_transaction_index_path(customer), params:
          }.not_to change { customer.customer_account_transactions.count }

          expect(response).to render_template("admin/customer_account_transaction/new")
          expect(response.body).to include(
            "cannot deduct more than the available credit ($20.00)"
          )
        end
      end

      context "when the customer has no credit" do
        let(:existing_credit) { 0 }

        it "does not allow any deduction" do
          expect {
            post admin_customer_customer_account_transaction_index_path(customer), params:
          }.not_to change { customer.customer_account_transactions.count }

          expect(response.body).to include("cannot deduct more than the available credit ($0.00)")
        end
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
