require 'spec_helper'

def travel_to(time)
  around { |example| Timecop.travel(start_of_july + time) { example.run } }
end


describe FinalizeAccountInvoices do
  describe "unit specs" do
    let!(:finalizer) { FinalizeAccountInvoices.new }
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    describe "perform" do
      let!(:accounts_distributor) { create(:distributor_enterprise) }
      let!(:invoice1) { create(:order, distributor: accounts_distributor, created_at: start_of_july - 10.days, completed_at: nil) }
      let!(:invoice2) { create(:order, distributor: accounts_distributor, created_at: start_of_july - 10.days, completed_at: start_of_july - 10.days) }
      let!(:invoice3) { create(:order, distributor: accounts_distributor, created_at: start_of_july, completed_at: nil) }
      let!(:invoice4) { create(:order, distributor: accounts_distributor, created_at: start_of_july + 10.days, completed_at: nil) }
      let!(:invoice5) { create(:order, distributor: accounts_distributor, created_at: start_of_july - 30.days, completed_at: nil) }

      before do
        allow(Enterprise).to receive(:find_by_id) { accounts_distributor }
        allow(accounts_distributor).to receive(:payment_methods) { double(:payment_methods, find_by_id: true) }
        allow(accounts_distributor).to receive(:shipping_methods) { double(:shipping_methods, find_by_id: true) }
        allow(finalizer).to receive(:finalize)
        allow(Bugsnag).to receive(:notify)
      end

      context "when necessary global config setting have not been set" do
        travel_to(20.days)

        context "when accounts_distributor has been set" do
          before do
            allow(Enterprise).to receive(:find_by_id) { false }
            finalizer.perform
          end

          it "snags errors and doesn't run" do
            expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("InvalidJobSettings"), anything)
            expect(finalizer).to_not have_received(:finalize)
          end
        end

        context "when default payment method has been set" do
          before do
            allow(accounts_distributor).to receive(:payment_methods) { double(:payment_methods, find_by_id: false) }
            finalizer.perform
          end

          it "snags errors and doesn't run" do
            expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("InvalidJobSettings"), anything)
            expect(finalizer).to_not have_received(:finalize)
          end
        end

        context "when default shipping method has been set" do
          before do
            allow(accounts_distributor).to receive(:shipping_methods) { double(:shipping_methods, find_by_id: false) }
            finalizer.perform
          end

          it "snags errors and doesn't run" do
            expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("InvalidJobSettings"), anything)
            expect(finalizer).to_not have_received(:finalize)
          end
        end
      end

      context "when necessary global config setting have been set" do
        context "and no date arguments are passed to the job" do
          travel_to(3.days)

          it "finalizes the uncompleted orders for accounts_distributor created in the previous calendar month" do
            finalizer.perform
            expect(finalizer).to have_received(:finalize).with(invoice1)
            expect(finalizer).to_not have_received(:finalize).with(invoice3)
            expect(finalizer).to_not have_received(:finalize).with(invoice2)
            expect(finalizer).to_not have_received(:finalize).with(invoice4)
            expect(finalizer).to have_received(:finalize).with(invoice5)
          end
        end

        context "and specfic start and end dates are passed as arguments" do
          let!(:finalizer) { FinalizeAccountInvoices.new(Time.now.year, 6) }

          before do
            allow(finalizer).to receive(:finalizer)
          end

          context "that ends in the past" do
            travel_to(3.hours)

            it "finalizes the uncompleted orders for accounts_distributor created in the specified calendar month" do
              finalizer.perform
              expect(finalizer).to have_received(:finalize).with(invoice1)
              expect(finalizer).to_not have_received(:finalize).with(invoice3)
              expect(finalizer).to_not have_received(:finalize).with(invoice2)
              expect(finalizer).to_not have_received(:finalize).with(invoice4)
              expect(finalizer).to have_received(:finalize).with(invoice5)
            end
          end

          context "that ends in the future" do
            travel_to -1.day

            it "does not finalize any orders" do
              finalizer.perform
              expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("InvalidJobSettings"), anything)
              expect(finalizer).to_not have_received(:finalize)
            end
          end
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
        finalizer.finalize(invoice)
        expect(invoice.completed_at).to_not be nil
        expect(invoice.payments.count).to eq 1
        expect(invoice.payments.first.payment_method).to eq pm
        expect(invoice.shipping_method).to eq sm
      end

      it "does not send a confirmation email" do
        expect(invoice).to receive(:deliver_order_confirmation_email).and_call_original
        expect{finalizer.finalize(invoice)}.to_not enqueue_job ConfirmOrderJob
      end
    end
  end

  describe "validation spec" do
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    let!(:updater) { UpdateAccountInvoices.new }
    let!(:finalizer) { FinalizeAccountInvoices.new }

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

    context "finalizing an invoice" do
      travel_to(3.hours)

      it "finalizes it" do
        # Create an invoice using the updater, to make sure we are using
        # an order as it would be when generated this way
        expect{updater.perform}.to change{Spree::Order.count}.from(0).to(1)
        invoice = user.orders.first

        # Finalize invoices
        finalizer.perform
        invoice.reload

        expect(invoice.completed_at).to_not be_nil
        expect(invoice.total).to eq billable_period1.bill
        expect(invoice.payments.count).to eq 1
        expect(invoice.payments.first.amount).to eq billable_period1.bill
        expect(invoice.state).to eq 'complete'
      end
    end
  end
end
