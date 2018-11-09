require "spec_helper"

feature "enterprise fee summary report" do
  include AuthenticationWorkflow
  include WebHelper

  let!(:distributor) { create(:distributor_enterprise) }
  let!(:other_distributor) { create(:distributor_enterprise) }

  before do
    login_as current_user
  end

  describe "navigation" do
    let(:current_user) { distributor.owner }

    before do
      visit spree.admin_reports_path
      click_on "Enterprise Fee Summary"
    end

    context "when accessing the report as an enterprise user" do
      it "allows access to the report" do
        expect(page).to have_button(I18n.t("generate_report", scope: i18n_scope))
      end
    end
  end

  def i18n_scope
    "spree.admin.reports.enterprise_fee_summary_report.filters"
  end
end
