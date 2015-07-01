require 'spec_helper'

def travel_to(time)
  around { |example| Timecop.travel(start_of_july + time) { example.run } }
end

describe UpdateUserInvoices do
  describe "units specs" do
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    let!(:updater) { UpdateUserInvoices.new }

    let!(:user) { create(:user) }
    let!(:old_billable_period) { create(:billable_period, owner: user, begins_at: start_of_july - 1.month, ends_at: start_of_july) }
    let!(:billable_period1) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 12.days) }
    let!(:billable_period2) { create(:billable_period, owner: user, begins_at: start_of_july + 12.days, ends_at: start_of_july + 20.days) }

    describe "perform" do
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
      let(:invoice) { create(:order, user: user) }

      before do
        allow(user).to receive(:current_invoice) { invoice }
        allow(updater).to receive(:finalize)
      end

      context "on the first of the month" do
        travel_to(3.hours)

        before do
          allow(updater).to receive(:adjustment_label_from).exactly(1).times.and_return("Old Item")
          allow(old_billable_period).to receive(:bill) { 666.66 }
          updater.update_invoice_for(user, [old_billable_period])
        end

        it "creates adjustments for each billing item" do
          adjustments = invoice.adjustments
          expect(adjustments.map(&:source_id)).to eq [old_billable_period.id]
          expect(adjustments.map(&:amount)).to eq [666.66]
          expect(adjustments.map(&:label)).to eq ["Old Item"]
        end

        it "finalizes the invoice" do
          expect(updater).to have_received(:finalize).with(invoice)
        end
      end

      context "on other days" do
        travel_to(20.days)

        before do
          allow(updater).to receive(:adjustment_label_from).exactly(2).times.and_return("BP1 Item", "BP2 Item")
          allow(billable_period1).to receive(:bill) { 123.45 }
          allow(billable_period2).to receive(:bill) { 543.21 }
          updater.update_invoice_for(user, [billable_period1, billable_period2])
        end

        it "creates adjustments for each billing item" do
          adjustments = invoice.adjustments
          expect(adjustments.map(&:source_id)).to eq [billable_period1.id, billable_period2.id]
          expect(adjustments.map(&:amount)).to eq [123.45, 543.21]
          expect(adjustments.map(&:label)).to eq ["BP1 Item", "BP2 Item"]
        end

        it "does not finalize the invoice" do
          expect(updater).to_not have_received(:finalize)
        end
      end
    end

    describe "finalize" do
      let!(:pm) { create(:payment_method, name: "PM1") }
      let!(:sm) { create(:shipping_method, name: "ship1") }
      let!(:enterprise) { create(:distributor_enterprise, payment_methods: [pm], shipping_methods: [sm]) }
      let!(:order) { create(:order, distributor: enterprise, shipping_method: sm) }

      before do
        order.line_items.clear
      end

      it "finalizes the order" do
        expect(order.completed_at).to be nil
        updater.finalize(order)
        expect(order.completed_at).to_not be nil
      end
    end
  end
end
