# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::CustomerAccountTransactionController do
  describe "GET /index" do
    let(:enterprise_user) { create(:user, enterprises: [enterprise]) }
    let(:enterprise) { create(:enterprise) }
    let(:customer) { create(:customer, enterprise:) }

    before do
      login_as enterprise_user
    end

    it "returns a list of customer transactions" do
      customer_account_transaction = create(:customer_account_transaction, customer:)

      get admin_customer_customer_account_transaction_index_path(customer),
          params: { format: :turbo_stream }

      expect(response).to render_template("admin/customer_account_transaction/index")
    end

    context "with a non authorized customer" do
      let(:customer) { create(:customer) }

      it "returns unauthorized" do
        customer_account_transaction = create(:customer_account_transaction, customer:)

        get admin_customer_customer_account_transaction_index_path(customer),
            params: { format: :turbo_stream }

        expect(response).to redirect_to(unauthorized_path)
      end
    end
  end
end
