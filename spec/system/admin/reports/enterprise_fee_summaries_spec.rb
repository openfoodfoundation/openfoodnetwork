# frozen_string_literal: true

require "system_helper"

RSpec.describe "enterprise fee summaries" do
  include AuthenticationHelper
  include WebHelper
  include ReportsHelper

  let!(:distributor) { create(:distributor_enterprise) }
  let!(:other_distributor) { create(:distributor_enterprise) }

  let!(:order_cycle) { create(:simple_order_cycle, coordinator: distributor) }
  let!(:other_order_cycle) { create(:simple_order_cycle, coordinator: other_distributor) }

  before do
    login_as current_user
  end

  describe "visiting the reports page" do
    before do
      visit admin_reports_path
    end

    describe "navigation" do
      context "when accessing the report as an superadmin" do
        let(:current_user) { create(:admin_user) }

        it "shows link and allows access to the report" do
          click_on 'Enterprise Fee Summary'
          expect(page).to have_button("Go")
        end
      end

      context "when accessing the report as an admin" do
        let(:current_user) { distributor.owner }

        it "shows link and allows access to the report" do
          click_on 'Enterprise Fee Summary'
          expect(page).to have_button("Go")
        end
      end

      context "when accessing the report as an enterprise user without sufficient permissions" do
        let(:current_user) { create(:user) }

        it "does not allow access to the report" do
          expect(page).not_to have_link('Enterprise Fee Summary')
          visit main_app.admin_report_path(report_type: 'enterprise_fee_summary')
          expect(page).to have_content('Unauthorized')
        end
      end
    end
  end

  describe "smoke test for filters" do
    before do
      visit main_app.admin_report_path(report_type: 'enterprise_fee_summary')
    end

    context "when logged in as admin" do
      let(:current_user) { create(:admin_user) }

      it "shows all available options" do
        expect(page).to have_select "q_order_cycle_ids", with_options: [order_cycle.name]
      end
    end

    context "when logged in as enterprise user" do
      let!(:order) do
        create(:completed_order_with_fees, order_cycle:,
                                           distributor:)
      end
      let(:current_user) { distributor.owner }

      it "shows available options for the enterprise" do
        expect(page).to have_select "q_order_cycle_ids", options: [order_cycle.name]
      end
    end
  end

  describe "permissions" do
    describe "smoke test for generation of report based on permissions" do
      let!(:order) do
        create(:completed_order_with_fees, order_cycle:,
                                           distributor:)
      end
      let!(:other_order) do
        create(:completed_order_with_fees, order_cycle: other_order_cycle,
                                           distributor: other_distributor)
      end
      context "when logged in as admin" do
        let!(:current_user) { create(:admin_user) }

        before do
          visit main_app.admin_report_path(report_type: 'enterprise_fee_summary')
        end

        it "generates file with data for all enterprises" do
          run_report
          expect(page).to have_content(distributor.name)
          expect(page).to have_content(other_distributor.name)
        end
      end

      context "when logged in as enterprise user" do
        let!(:current_user) { distributor.owner }

        before do
          visit main_app.admin_report_path(report_type: 'enterprise_fee_summary')
        end

        it "generates file with data for the enterprise" do
          run_report
          expect(page).to have_content(distributor.name)
          expect(page).not_to have_content(other_distributor.name)
        end
      end
    end

    describe "downloading the report" do
      let!(:second_distributor) { create(:distributor_enterprise) }
      let!(:second_order_cycle) { create(:simple_order_cycle, coordinator: second_distributor) }
      let!(:order) do
        create(:completed_order_with_fees, order_cycle:,
                                           distributor:)
      end
      let!(:second_order) do
        create(:completed_order_with_fees, order_cycle: second_order_cycle,
                                           distributor: second_distributor)
      end

      let(:current_user) { create(:admin_user) }

      before do
        visit main_app.admin_report_path(report_type: 'enterprise_fee_summary')
        find("#s2id_q_order_cycle_ids").click
        select order_cycle.name
      end

      shared_examples "reports generated as" do |output_type, extension|
        context output_type.to_s do
          it "downloads the #{output_type} file" do
            select output_type, from: "report_format"

            expect { generate_report }.to change { downloaded_filenames.length }.from(0).to(1)

            expect(downloaded_filename).to match(/.*\.#{extension}/)

            downloaded_file_txt = load_file_txt(extension, downloaded_filename)

            expect(downloaded_file_txt).to have_content(distributor.name)
            expect(downloaded_file_txt).not_to have_content(second_distributor.name)
          end
        end
      end

      it_behaves_like "reports generated as", "CSV", "csv"
      it_behaves_like "reports generated as", "Spreadsheet", "xlsx"
    end
  end

  def i18n_scope
    "order_management.reports.enterprise_fee_summaries"
  end
end
