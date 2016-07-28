require 'spec_helper'

feature 'Schedules', js: true do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user" do
    let(:user) { create(:user) }
    let(:managed_enterprise) { create(:distributor_enterprise, owner: user) }
    let(:unmanaged_enterprise) { create(:distributor_enterprise) }
    let!(:oc1) { create(:simple_order_cycle, coordinator: managed_enterprise, name: 'oc1') }
    let!(:oc2) { create(:simple_order_cycle, coordinator: managed_enterprise, name: 'oc2') }
    let!(:oc3) { create(:simple_order_cycle, coordinator: managed_enterprise, name: 'oc3') }
    let!(:oc4) { create(:simple_order_cycle, coordinator: unmanaged_enterprise, name: 'oc4') }
    let!(:weekly_schedule) { create(:schedule, name: 'Weekly', order_cycles: [oc1, oc2, oc3, oc4]) }

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
      let!(:fortnightly_schedule) { create(:schedule, name: 'Fortnightly', order_cycles: [oc1, oc3]) }

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
