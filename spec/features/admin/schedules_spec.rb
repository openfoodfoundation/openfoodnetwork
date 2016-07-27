require 'spec_helper'

feature 'Schedules', js: true do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user" do
    let(:user) { create(:user) }
    let(:managed_enterprise) { create(:distributor_enterprise, owner: user) }
    let(:unmanaged_enterprise) { create(:distributor_enterprise) }
    let!(:weekly_schedule) { create(:schedule, name: 'Weekly') }
    let!(:fortnightly_schedule) { create(:schedule, name: 'Fortnightly') }
    let!(:oc1) { create(:order_cycle, coordinator: managed_enterprise, name: 'oc1', schedules: [weekly_schedule]) }
    let!(:oc2) { create(:order_cycle, coordinator: managed_enterprise, name: 'oc2', schedules: [weekly_schedule]) }
    let!(:oc3) { create(:order_cycle, coordinator: managed_enterprise, name: 'oc3', schedules: [weekly_schedule]) }
    let!(:oc4) { create(:order_cycle, coordinator: unmanaged_enterprise, name: 'oc4', schedules: [weekly_schedule]) }

    before { login_to_admin_as user }

    describe "Adding a new Schedule" do
      it "immediately shows the schedule in the order cycle list once created" do
        click_link 'Order Cycles'
        expect(page).to have_selector ".order-cycle-#{oc1.id}"
        find('a', text: 'NEW SCHEDULE').click

        within "#schedule-dialog" do
          expect(page).to have_selector '#available-order-cycles .order-cycle', text: oc1.name
          expect(page).to have_selector '#available-order-cycles .order-cycle', text: oc2.name
          expect(page).to have_selector '#available-order-cycles .order-cycle', text: oc3.name
          expect(page).to have_no_selector '#available-order-cycles .order-cycle', text: oc4.name
          fill_in 'name', with: "Fortnightly"
          find("#available-order-cycles .order-cycle", text: oc1.name).drag_to find("#selected-order-cycles")
          find("#available-order-cycles .order-cycle", text: oc3.name).drag_to find("#selected-order-cycles")
          click_button "Create Schedule"
        end

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
      use_short_wait
      before do
        oc1.update_attributes(schedule_ids: [weekly_schedule.id, fortnightly_schedule.id])
        oc3.update_attributes(schedule_ids: [weekly_schedule.id, fortnightly_schedule.id])
      end

      it "immediately shows updated schedule lists for order cycles" do
        click_link 'Order Cycles'

        within ".order-cycle-#{oc1.id} td.schedules" do
          find('a', text: "Weekly").click
        end

        within "#schedule-dialog" do
          find("#selected-order-cycles .order-cycle", text: oc3.name).drag_to find("#available-order-cycles")
          click_button "Update Schedule"
        end

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
  end
end
