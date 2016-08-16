require 'spec_helper'

def travel_to(time)
  around { |example| Timecop.travel(start_of_july + time) { example.run } }
end


describe FinalizeAccountInvoices do
  let!(:year) { Time.zone.now.year }

  describe "unit specs" do
    let!(:finalizer) { FinalizeAccountInvoices.new }
    let!(:start_of_july) { Time.zone.local(year, 7) }

    describe "perform" do
      let!(:accounts_distributor) { create(:distributor_enterprise) }

      #Invoice from June
      let!(:account_invoice1) { create(:account_invoice, year: year, month: 6, order: create(:order, completed_at: nil))}

      # We don't care when it was completed, in the future or past
      let!(:account_invoice2) { create(:account_invoice, year: year, month: 6, order: create(:order, completed_at: start_of_july - 10.days))}
      let!(:account_invoice3) { create(:account_invoice, year: year, month: 6, order: create(:order, completed_at: start_of_july + 10.days))}

      # Invoices from July
      let!(:account_invoice4) { create(:account_invoice, year: year, month: 7, order: create(:order, completed_at: nil))}
      let!(:account_invoice5) { create(:account_invoice, year: year, month: 7, order: create(:order, completed_at: start_of_july + 10.days))}

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

          it "finalizes the uncompleted orders from account_invoices for the previous calendar month" do
            finalizer.perform
            expect(finalizer).to have_received(:finalize).with(account_invoice1.order)
            expect(finalizer).to_not have_received(:finalize).with(account_invoice2.order)
            expect(finalizer).to_not have_received(:finalize).with(account_invoice3.order)
            expect(finalizer).to_not have_received(:finalize).with(account_invoice4.order)
            expect(finalizer).to_not have_received(:finalize).with(account_invoice5.order)
          end
        end

        context "and a specific year and month are passed as arguments" do
          let!(:finalizer) { FinalizeAccountInvoices.new(year, 7) }

          before do
            allow(finalizer).to receive(:finalizer)
          end

          context "that ends in the past" do
            travel_to(1.month + 3.hours)

            it "finalizes the uncompleted orders from account_invoices for the specified calendar month" do
              finalizer.perform
              expect(finalizer).to_not have_received(:finalize).with(account_invoice1.order)
              expect(finalizer).to_not have_received(:finalize).with(account_invoice2.order)
              expect(finalizer).to_not have_received(:finalize).with(account_invoice3.order)
              expect(finalizer).to have_received(:finalize).with(account_invoice4.order)
              expect(finalizer).to_not have_received(:finalize).with(account_invoice5.order)
            end
          end

          context "that ends in the future" do
            travel_to 3.days

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
      let!(:invoice_order) { create(:order, distributor: accounts_distributor) }

      before do
        Spree::Config.set({ accounts_distributor_id: accounts_distributor.id })
        Spree::Config.set({ default_accounts_payment_method_id: pm.id })
        Spree::Config.set({ default_accounts_shipping_method_id: sm.id })
        invoice_order.line_items.clear
      end

      it "creates payment, assigns shipping method and finalizes the order" do
        expect(invoice_order.completed_at).to be nil
        finalizer.finalize(invoice_order)
        expect(invoice_order.completed_at).to_not be nil
        expect(invoice_order.payments.count).to eq 1
        expect(invoice_order.payments.first.payment_method).to eq pm
        expect(invoice_order.shipping_method).to eq sm
      end

      it "does not send a confirmation email" do
        expect(invoice_order).to receive(:deliver_order_confirmation_email).and_call_original
        expect{finalizer.finalize(invoice_order)}.to_not enqueue_job ConfirmOrderJob
      end

      context "when errors exist on the order" do
        before do
          allow(invoice_order).to receive(:errors) { double(:errors, any?: true, full_messages: ["Error message 1", "Error message 2"]) }
          allow(Bugsnag).to receive(:notify)
        end

        it "Snags a bug and does not finalize the order" do
          finalizer.finalize(invoice_order)
          expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("FinalizeInvoiceError"), anything)
          expect(invoice_order).to_not be_completed
        end
      end
    end
  end

  describe "validation spec" do
    let!(:start_of_july) { Time.zone.local(year, 7) }

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

      # Make sure that bills are > 0
      Spree::Config.set(:account_invoices_monthly_fixed, 5)
      Spree::Config.set(:account_invoices_monthly_rate, 0.02)
      Spree::Config.set(:account_invoices_monthly_cap, 50)
      Spree::Config.set(:minimum_billable_turnover, 0)
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
        expect(invoice.total).to eq billable_period1.bill.round(2)
        expect(invoice.payments.count).to eq 1
        expect(invoice.payments.first.amount).to eq billable_period1.bill.round(2)
        expect(invoice.state).to eq 'complete'
      end
    end
  end
end
