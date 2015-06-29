require 'spec_helper'

def travel_to(time)
  around { |example| Timecop.travel(start_of_july + time) { example.run } }
end

describe UpdateUserInvoices do
  describe "units specs" do
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    let!(:updater) { UpdateUserInvoices.new }

    describe "perform" do
      let!(:user) { create(:user) }
      let!(:old_billable_period) { create(:billable_period, owner: user, begins_at: start_of_july - 1.month, ends_at: start_of_july) }
      let!(:billable_period1) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 12.days) }
      let!(:billable_period2) { create(:billable_period, owner: user, begins_at: start_of_july + 12.days, ends_at: start_of_july + 20.days) }

      before do
        allow(updater).to receive(:update_invoice_for)
      end

      context "on the first of the month" do
        travel_to(3.hours)

        it "updates the user's current invoice with billable_periods from the previous month" do
          updater.perform
          expect(updater).to have_received(:update_invoice_for).once
          .with(user, [old_billable_period])
        end
      end

      context "on other days" do
        travel_to(20.days)

        it "updates the user's current invoice with billable_periods from the current month" do
          updater.perform
          expect(updater).to have_received(:update_invoice_for).once
          .with(user, [billable_period1, billable_period2])
        end
      end
    end

    describe "update_invoice_for" do
      let!(:user) { create(:user) }
      let!(:billable_period1) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 12.days) }
      let!(:billable_period2) { create(:billable_period, owner: user, begins_at: start_of_july + 12.days, ends_at: start_of_july + 20.days) }


    end
  end
end
