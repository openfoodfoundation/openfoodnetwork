require "spec_helper"

describe Spree::Admin::Reports::EnterpriseFeeSummariesController, type: :controller do
  let(:report_klass) { OrderManagement::Reports::EnterpriseFeeSummary }

  let!(:admin) { create(:admin_user) }

  let(:current_user) { admin }

  before do
    allow(controller).to receive(:spree_current_user) { current_user }
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

    context "when some parameters are now allowed" do
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:other_distributor) { create(:distributor_enterprise) }

      let(:current_user) { distributor.owner }

      it "renders the report form with an error" do
        get :index, report: { distributor_ids: [other_distributor.id] }, report_format: "csv"

        expect(flash[:error]).to eq(report_klass::Authorizer::PARAMETER_NOT_ALLOWED_ERROR)
        expect(response)
          .to render_template("spree/admin/reports/enterprise_fee_summaries/index")
      end
    end

    describe "filtering results based on permissions" do
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:other_distributor) { create(:distributor_enterprise) }

      let!(:order_cycle) { create(:simple_order_cycle, coordinator: distributor) }
      let!(:other_order_cycle) { create(:simple_order_cycle, coordinator: other_distributor) }

      let(:current_user) { distributor.owner }

      it "applies permissions to report" do
        get :index, report: {}, report_format: "csv"

        expect(assigns(:permissions).allowed_order_cycles.to_a).to eq([order_cycle])
      end
    end
  end

  def i18n_scope
    "order_management.reports.enterprise_fee_summary"
  end

  def view_template_path
    "spree/admin/reports/enterprise_fee_summaries/index"
  end
end
