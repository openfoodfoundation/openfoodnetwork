# frozen_string_literal: true

require 'system_helper'

describe 'Schedules' do
  include AuthenticationHelper
  include WebHelper

  context "as an enterprise user" do
    let(:user) { create(:user, enterprise_limit: 10) }
    let(:managed_enterprise) {
      create(:distributor_enterprise, owner: user, enable_subscriptions: true)
    }
    let(:unmanaged_enterprise) { create(:distributor_enterprise, enable_subscriptions: true) }
    let(:managed_enterprise2) {
      create(:distributor_enterprise, owner: user, enable_subscriptions: true)
    }
    let!(:oc1) { create(:simple_order_cycle, coordinator: managed_enterprise, name: 'oc1') }
    let!(:oc2) { create(:simple_order_cycle, coordinator: managed_enterprise, name: 'oc2') }
    let!(:oc3) { create(:simple_order_cycle, coordinator: managed_enterprise, name: 'oc3') }
    let!(:oc4) {
      create(:simple_order_cycle, coordinator: unmanaged_enterprise, distributors: [managed_enterprise],
                                  name: 'oc4')
    }
    let!(:oc5) { create(:simple_order_cycle, coordinator: managed_enterprise2, name: 'oc5') }
    let!(:weekly_schedule) { create(:schedule, name: 'Weekly', order_cycles: [oc1, oc2, oc3, oc4]) }

    before { login_as user }

    describe "Adding a new Schedule" do
      it "immediately shows the schedule in the order cycle list once created" do
        visit spree.admin_dashboard_path
        click_link 'Order Cycles'
        expect(page).to have_selector ".order-cycle-#{oc1.id}"
        find('a', text: 'NEW SCHEDULE').click

        within "#schedule-dialog" do
          # Only order cycles coordinated by managed enterprises are available to select
          expect(page).to have_selector '#available-order-cycles .order-cycle', text: oc1.name
          expect(page).to have_selector '#available-order-cycles .order-cycle', text: oc2.name
          expect(page).to have_selector '#available-order-cycles .order-cycle', text: oc3.name
          expect(page).to have_no_selector '#available-order-cycles .order-cycle', text: oc4.name
          expect(page).to have_selector '#available-order-cycles .order-cycle', text: oc5.name
          fill_in 'name', with: "Fortnightly"
          find("#available-order-cycles .order-cycle", text: oc1.name).click
          find("#add-remove-buttons a.add").click
          # Selection of an order cycles limits available options to those with the same coordinator
          expect(page).to have_no_selector '#available-order-cycles .order-cycle', text: oc5.name
          find("#available-order-cycles .order-cycle", text: oc3.name).click
          find("#add-remove-buttons a.add").click
          click_button "Create Schedule"
        end

        save_bar = find("#save-bar")
        expect(save_bar).to have_content "Created schedule: 'Fortnightly'"

        within ".order-cycle-#{oc1.id} td.schedules" do
          expect(page).to have_selector "a", text: "Weekly"
          expect(page).to have_selector "a", text: "Fortnightly"
        end

        within ".order-cycle-#{oc2.id} td.schedules" do
          expect(page).to have_selector "a", text: "Weekly"
          expect(page).to have_no_selector "a", text: "Fortnightly"
        end

        within ".order-cycle-#{oc3.id} td.schedules" do
          expect(page).to have_selector "a", text: "Weekly"
          expect(page).to have_selector "a", text: "Fortnightly"
        end
      end
    end

    describe "updating existing schedules" do
      let!(:fortnightly_schedule) {
        create(:schedule, name: 'Fortnightly', order_cycles: [oc1, oc3])
      }

      it "immediately shows updated schedule lists for order cycles" do
        visit admin_order_cycles_path

        within ".order-cycle-#{oc1.id} td.schedules" do
          find('a', text: "Weekly").click
        end

        expect(page).to have_selector "#schedule-dialog"
        within "#schedule-dialog" do
          find("#selected-order-cycles .order-cycle", text: oc3.name).click
          find("#add-remove-buttons a.remove").click
          click_button "Update Schedule"
        end

        save_bar = find("#save-bar")
        expect(save_bar).to have_content "Updated schedule: 'Weekly'"

        within ".order-cycle-#{oc1.id} td.schedules" do
          expect(page).to have_selector "a", text: "Weekly"
          expect(page).to have_selector "a", text: "Fortnightly"
        end

        within ".order-cycle-#{oc2.id} td.schedules" do
          expect(page).to have_selector "a", text: "Weekly"
          expect(page).to have_no_selector "a", text: "Fortnightly"
        end

        within ".order-cycle-#{oc3.id} td.schedules" do
          expect(page).to have_no_selector "a", text: "Weekly"
          expect(page).to have_selector "a", text: "Fortnightly"
        end
      end
    end

    describe "deleting a schedule" do
      it "immediately removes deleted schedules from order cycles" do
        visit admin_order_cycles_path

        within ".order-cycle-#{oc1.id} td.schedules" do
          find('a', text: "Weekly").click
        end

        within "#schedule-dialog" do
          accept_alert do
            click_button "Delete Schedule"
          end
        end

        save_bar = find("#save-bar")
        expect(save_bar).to have_content "Deleted schedule: 'Weekly'"

        within ".order-cycle-#{oc1.id} td.schedules" do
          expect(page).to have_no_selector "a", text: "Weekly"
        end

        within ".order-cycle-#{oc2.id} td.schedules" do
          expect(page).to have_no_selector "a", text: "Weekly"
        end

        within ".order-cycle-#{oc3.id} td.schedules" do
          expect(page).to have_no_selector "a", text: "Weekly"
        end

        expect(Schedule.find_by(id: weekly_schedule.id)).to be_nil
        expect(oc1.reload.schedules).to eq []
        expect(oc2.reload.schedules).to eq []
        expect(oc3.reload.schedules).to eq []
        expect(oc4.reload.schedules).to eq []
      end
    end
  end
end
