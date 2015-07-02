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

        it "saves to invoice" do
          expect(invoice).to have_received(:save).once
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

        it "saves to invoice" do
          expect(invoice).to have_received(:save).once
        end

        it "does not finalize the invoice" do
          expect(updater).to_not have_received(:finalize)
        end
      end
    end

    describe "finalize" do
      let!(:pm) { create(:payment_method, name: "PM1") }
      let!(:sm) { create(:shipping_method, name: "ship1") }
      let!(:accounts_distributor) { create(:distributor_enterprise, payment_methods: [pm], shipping_methods: [sm]) }
      let!(:invoice) { create(:order, distributor: accounts_distributor) }

      before do
        Spree::Config.set({ accounts_distributor_id: accounts_distributor.id })
        Spree::Config.set({ default_accounts_payment_method_id: pm.id })
        Spree::Config.set({ default_accounts_shipping_method_id: sm.id })
        invoice.line_items.clear
      end

      it "creates payment, assigns shipping method and finalizes the order" do
        expect(invoice.completed_at).to be nil
        updater.finalize(invoice)
        expect(invoice.completed_at).to_not be nil
        expect(invoice.payments.count).to eq 1
        expect(invoice.payments.first.payment_method).to eq pm
        expect(invoice.shipping_method).to eq sm
      end
    end
  end

  describe "validation spec" do
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    let!(:updater) { UpdateUserInvoices.new }

    let!(:pm) { create(:payment_method, name: "Default Payment Method") }
    let!(:sm) { create(:shipping_method, name: "Default Shipping Method") }
    let!(:accounts_distributor) { create(:distributor_enterprise, payment_methods: [pm], shipping_methods: [sm]) }

    let!(:user) { create(:user) }
    let!(:billable_period1) { create(:billable_period, sells: 'any', owner: user, begins_at: start_of_july - 1.month, ends_at: start_of_july) }
    let!(:billable_period2) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 10.days) }
    let!(:billable_period3) { create(:billable_period, owner: user, begins_at: start_of_july + 12.days, ends_at: start_of_july + 20.days) }

    before do
      sm.calculator.set_preference(:amount, 0); sm.calculator.save!

      Spree::Config.set({ accounts_distributor_id: accounts_distributor.id })
      Spree::Config.set({ default_accounts_payment_method_id: pm.id })
      Spree::Config.set({ default_accounts_shipping_method_id: sm.id })
    end

    context "updating an invoice" do
      travel_to(20.days)

      it "does not creates an invoice when one does not already exist, but does not finalize it" do
        expect{updater.perform}.to change{Spree::Order.count}.from(0).to(1)
        invoice = user.orders.first
        expect(invoice.completed_at).to be_nil
        expect(invoice.total).to eq billable_period2.bill + billable_period3.bill
        expect(invoice.payments.count).to eq 0
        expect(invoice.state).to eq 'cart'
      end
    end

    context "finalizing an invoice" do
      travel_to(3.hours)

      it "creates an invoice and finalizes it" do
        expect{updater.perform}.to change{Spree::Order.count}.from(0).to(1)
        invoice = user.orders.first
        expect(invoice.completed_at).to_not be_nil
        expect(invoice.total).to eq billable_period1.bill
        expect(invoice.payments.count).to eq 1
        expect(invoice.payments.first.amount).to eq billable_period1.bill
        expect(invoice.state).to eq 'complete'
      end
    end
  end
end
