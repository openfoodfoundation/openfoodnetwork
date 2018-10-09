require "spec_helper"

describe Spree::Admin::Reports::EnterpriseFeeSummaryReportController, type: :controller do
  let!(:admin) { create(:admin_user) }

  let(:current_user) { admin }

  before do
    allow(controller).to receive(:spree_current_user) { admin }
  end

  describe "#index" do
    context "when there are no parameters" do
      it "renders the report form" do
        get :index

        expect(response).to be_success
        expect(response).to render_template(view_template_path)
      end
    end

    context "when the parameters are valid" do
      it "sends the generated report in the correct format" do
        get :index, report: { start_at: "2018-10-09 07:30:00" }, report_format: "csv"

        expect(response).to be_success
        expect(response.body).not_to be_blank
        expect(response.header["Content-Type"]).to eq("text/csv")
      end
    end

    context "when the parameters are invalid" do
      it "renders the report form with an error" do
        get :index, report: { start_at: "invalid date" }, report_format: "csv"

        expect(flash[:error]).to eq(I18n.t("invalid_filter_parameters", scope: i18n_scope))
        expect(response).to render_template(view_template_path)
      end
    end
  end

  def i18n_scope
    "order_management.reports.enterprise_fee_summary"
  end

  def view_template_path
    "spree/admin/reports/enterprise_fee_summary_report/index"
  end
end
