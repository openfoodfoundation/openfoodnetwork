# frozen_string_literal: true

require "spec_helper"

describe Admin::VouchersController, type: :request do
  let(:enterprise) { create(:supplier_enterprise, name: "Feedme") }
  let(:enterprise_user) { create(:user, enterprise_limit: 1) }

  before do
    Flipper.enable(:vouchers)

    enterprise_user.enterprise_roles.build(enterprise: enterprise).save
    sign_in enterprise_user
  end

  describe "GET /admin/enterprises/:enterprise_id/vouchers/new" do
    it "loads the new voucher page" do
      get new_admin_enterprise_voucher_path(enterprise)

      expect(response).to render_template("admin/vouchers/new")
    end
  end

  describe "POST /admin/enterprises/:enterprise_id/vouchers" do
    subject(:create_voucher) { post admin_enterprise_vouchers_path(enterprise), params: params }

    let(:params) do
      {
        vouchers_flat_rate: {
          code: code,
          amount: amount,
          voucher_type: type
        }
      }
    end
    let(:code) { "new_code" }
    let(:amount) { 15 }
    let(:type) { "Vouchers::PercentageRate" }

    context "with a flat rate voucher" do
      let(:type) { "Vouchers::FlatRate" }

      it "creates a new voucher" do
        expect { create_voucher }.to change(Vouchers::FlatRate, :count).by(1)

        voucher = Vouchers::FlatRate.last
        expect(voucher.code).to eq(code)
        expect(voucher.amount).to eq(amount)
      end
    end

    context "with a percentage rate voucher" do
      let(:type) { "Vouchers::PercentageRate" }

      it "creates a new voucher" do
        expect { create_voucher }.to change(Vouchers::PercentageRate, :count).by(1)

        voucher = Vouchers::PercentageRate.last
        expect(voucher.code).to eq(code)
        expect(voucher.amount).to eq(amount)
      end
    end

    context "with a wrong type" do
      let(:type) { "Random" }

      it "render the new page with an error" do
        create_voucher

        expect(response).to render_template("admin/vouchers/new")
        expect(flash[:error]).to eq("Type is invalid")
      end
    end

    it "redirects to admin enterprise setting page, voucher panel" do
      create_voucher

      expect(response).to redirect_to("#{edit_admin_enterprise_path(enterprise)}#vouchers_panel")
    end
  end
end
