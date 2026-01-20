# frozen_string_literal: true

RSpec.describe "/payments/:id/authorize" do
  let!(:user) { create(:user) }
  let!(:order) { create(:order, user:) }
  let!(:payment) { create(:payment, order:) }

  describe "when user isn't logged in" do
    it "redirects to the login page and set error flash msg" do
      get authorize_payment_path(payment)
      expect(response).to redirect_to(root_path(anchor: "/login", after_login: request.fullpath))
      expect(flash[:error]).to eq I18n.t("spree.orders.edit.login_to_view_order")
    end
  end

  describe "when user is logged in" do
    before { sign_in user }

    context "has redirect auth url" do
      before do
        allow_any_instance_of(Spree::Payment).to receive(:redirect_auth_url).and_return('http://example.com')
      end

      it "redirects to the 3D-Auth url" do
        get authorize_payment_path(payment)
        expect(response).to redirect_to('http://example.com')
      end
    end

    context "doesn't have redirect auth url" do
      it "redirect to order URL" do
        get authorize_payment_path(payment)
        expect(response).to redirect_to(order_url(order))
      end
    end
  end
end
