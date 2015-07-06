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
      let(:accounts_distributor) { double(:accounts_distributor) }
      before do
        allow(Enterprise).to receive(:find_by_id) { accounts_distributor }
        allow(updater).to receive(:update_invoice_for)
      end

      context "when necessary global config setting have not been set" do
        travel_to(20.days)

        context "when accounts_distributor has been set" do
          before do
            allow(Enterprise).to receive(:find_by_id) { false }
            updater.perform
          end

          it "doesn't run" do
            expect(updater).to_not have_received(:update_invoice_for)
          end
        end
      end

      context "when necessary global config setting have been set" do
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
    end

    describe "update_invoice_for" do
      let(:invoice) { create(:order, user: user) }

      before do
        allow(user).to receive(:current_invoice) { invoice }
        allow(invoice).to receive(:save)
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

        it "saves the invoice" do
          expect(invoice).to have_received(:save).once
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

        it "saves to invoice" do
          expect(invoice).to have_received(:save).once
        end
      end
    end
  end

  describe "validation spec" do
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    let!(:updater) { UpdateUserInvoices.new }

    let!(:accounts_distributor) { create(:distributor_enterprise) }

    let!(:user) { create(:user) }
    let!(:billable_period1) { create(:billable_period, sells: 'any', owner: user, begins_at: start_of_july - 1.month, ends_at: start_of_july) }
    let!(:billable_period2) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 10.days) }
    let!(:billable_period3) { create(:billable_period, owner: user, begins_at: start_of_july + 12.days, ends_at: start_of_july + 20.days) }

    before do
      Spree::Config.set({ accounts_distributor_id: accounts_distributor.id })
    end

    context "updating an invoice" do
      travel_to(20.days)

      it "creates an invoice when one does not already exist" do
        expect{updater.perform}.to change{Spree::Order.count}.from(0).to(1)
        invoice = user.orders.first
        expect(invoice.completed_at).to be_nil
        expect(invoice.total).to eq billable_period2.bill + billable_period3.bill
        expect(invoice.payments.count).to eq 0
        expect(invoice.state).to eq 'cart'
      end
    end
  end
end
