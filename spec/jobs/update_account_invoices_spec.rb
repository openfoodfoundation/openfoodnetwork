require 'spec_helper'

def travel_to(time)
  around { |example| Timecop.travel(start_of_july + time) { example.run } }
end

describe UpdateAccountInvoices do
  let(:year) { Time.zone.now.year }

  before do
    # Make sure that bills are > 0
    Spree::Config.set(:account_invoices_monthly_fixed, 5)
    Spree::Config.set(:account_invoices_monthly_rate, 0.02)
    Spree::Config.set(:account_invoices_monthly_cap, 50)
    Spree::Config.set(:minimum_billable_turnover, 0)
  end

  describe "units specs" do
    let!(:start_of_july) { Time.zone.local(year, 7) }

    let!(:updater) { UpdateAccountInvoices.new }

    let!(:user) { create(:user) }
    let!(:june_billable_period1) { create(:billable_period, owner: user, begins_at: start_of_july - 1.month, ends_at: start_of_july - 20.days) }
    let!(:june_billable_period2) { create(:billable_period, owner: user, begins_at: start_of_july - 20.days, ends_at: start_of_july - 10.days, turnover: 45, sells: "none" ) }
    let!(:june_billable_period3) { create(:billable_period, owner: user, begins_at: start_of_july - 10.days, ends_at: start_of_july - 1.days, turnover: 0, sells: "any" ) }
    let!(:july_billable_period1) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 12.days) }
    let!(:july_billable_period2) { create(:billable_period, owner: user, begins_at: start_of_july + 12.days, ends_at: start_of_july + 20.days) }
    let!(:july_billable_period3) { create(:billable_period, owner: user, begins_at: start_of_july + 20.days, ends_at: start_of_july + 25.days, turnover: 45, sells: 'none') }
    let!(:july_billable_period4) { create(:billable_period, owner: user, begins_at: start_of_july + 25.days, ends_at: start_of_july + 28.days, turnover: 0, sells: 'any') }
    let(:june_account_invoice) { june_billable_period1.account_invoice }
    let(:july_account_invoice) { july_billable_period1.account_invoice }

    describe "perform" do
      let(:accounts_distributor) { double(:accounts_distributor) }
      before do
        allow(Enterprise).to receive(:find_by_id) { accounts_distributor }
        allow(updater).to receive(:update)
        allow(Bugsnag).to receive(:notify)
      end

      context "when necessary global config setting have not been set" do
        travel_to(20.days)

        context "when accounts_distributor has been set" do
          before do
            allow(Enterprise).to receive(:find_by_id) { false }
            updater.perform
          end

          it "snags errors and doesn't run" do
            expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("InvalidJobSettings"), anything)
            expect(updater).to_not have_received(:update)
          end
        end
      end

      context "when necessary global config setting have been set" do
        context "on the first of the month" do
          travel_to(3.hours)

          it "updates invoices from the previous month" do
            updater.perform
            expect(updater).to have_received(:update).once
              .with(june_account_invoice)
            expect(updater).to_not have_received(:update)
              .with(july_account_invoice)
          end
        end

        context "on other days" do
          travel_to(20.days)

          it "updates invoices from the current month" do
            updater.perform
            expect(updater).to have_received(:update).once
              .with(july_account_invoice)
          end
        end

        context "when specfic a specific month (and year) are passed as arguments" do
          let!(:updater) { UpdateAccountInvoices.new(year, 7) }

          before do
            allow(updater).to receive(:update)
          end

          context "that just ended (in the past)" do
            travel_to(1.month)

            it "updates invoices from the previous month" do
              updater.perform
              expect(updater).to have_received(:update).once
                .with(july_account_invoice)
            end
          end

          context "that starts in the past and ends in the future (ie. current_month)" do
            travel_to 30.days

            it "updates invoices from that current month" do
              updater.perform
              expect(updater).to have_received(:update).once
                .with(july_account_invoice)
            end
          end

          context "that starts in the future" do
            travel_to(-1.days)

            it "snags an error and does not update invoices" do
              updater.perform
              expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("InvalidJobSettings"), anything)
              expect(updater).to_not have_received(:update)
            end
          end
        end
      end
    end

    describe "update" do
      before do
        allow(june_account_invoice).to receive(:save).and_call_original
        allow(july_account_invoice).to receive(:save).and_call_original
        allow(updater).to receive(:clean_up)
        allow(updater).to receive(:finalize)
        allow(Bugsnag).to receive(:notify)
      end

      context "where an order for the invoice already exists" do
        let!(:invoice_order) { create(:order, user: user) }

        before do
          expect(Spree::Order).to_not receive(:new)
          allow(june_account_invoice).to receive(:order) { invoice_order }
        end

        context "where the order is already complete" do
          before do
            allow(invoice_order).to receive(:complete?) { true }
            updater.update(june_account_invoice)
          end

          it "snags a bug" do
            expect(Bugsnag).to have_received(:notify)
          end

          it "does not save the order" do
            expect(june_account_invoice).to_not have_received(:save)
          end

          it "does not clean up the order" do
            expect(updater).to_not have_received(:clean_up).with(invoice_order, anything)
          end
        end

        context "where the order is not complete" do
          before do
            allow(invoice_order).to receive(:complete?) { false }
            june_billable_period1.enterprise.update_attributes(contact: "Firstname Lastname Something Else", phone: '12345')
            updater.update(june_account_invoice)
          end

          it "creates adjustments for each billing item where bill is not 0" do
            adjustments = invoice_order.adjustments
            expect(adjustments.map(&:source_id)).to eq [june_billable_period1.id, june_billable_period3.id]
            expect(adjustments.map(&:amount)).to eq [june_billable_period1.bill.round(2), june_billable_period3.bill.round(2)]
            expect(adjustments.map(&:label)).to eq [june_billable_period1.adjustment_label, june_billable_period3.adjustment_label]
          end

          it "assigns a addresses to the order" do
            expect(invoice_order.billing_address).to be_a Spree::Address
            expect(invoice_order.shipping_address).to be_a Spree::Address
            expect(invoice_order.shipping_address).to eq invoice_order.billing_address
            [:address1, :address2, :city, :zipcode, :state_id, :country_id].each do |attr|
              expect(invoice_order.billing_address[attr]).to eq june_billable_period1.enterprise.address[attr]
            end
            expect(invoice_order.billing_address.firstname).to eq "Firstname"
            expect(invoice_order.billing_address.lastname).to eq "Lastname Something Else"
            expect(invoice_order.billing_address.phone).to eq "12345"
          end

          it "saves the order" do
            expect(june_account_invoice).to have_received(:save)
            expect(june_account_invoice.order).to be_persisted
          end

          it "cleans up the order" do
            expect(updater).to have_received(:clean_up).with(invoice_order, anything).once
          end
        end
      end

      context "where an order for the invoice does not already exist" do
        let!(:accounts_distributor) { create(:distributor_enterprise) }
        before do
          Spree::Config.set({ accounts_distributor_id: accounts_distributor.id })
          updater.update(july_account_invoice)
        end

        it "creates adjustments for each billing item where bill is not 0" do
          adjustments = july_account_invoice.order.adjustments
          expect(adjustments.map(&:source_id)).to eq [july_billable_period1.id, july_billable_period2.id,july_billable_period4.id]
          expect(adjustments.map(&:amount)).to eq [july_billable_period1.bill.round(2), july_billable_period2.bill.round(2), july_billable_period4.bill.round(2)]
          expect(adjustments.map(&:label)).to eq [july_billable_period1.adjustment_label, july_billable_period2.adjustment_label, july_billable_period4.adjustment_label]
        end

        it "saves the order" do
          expect(july_account_invoice).to have_received(:save)
          expect(july_account_invoice.order).to be_persisted
        end

        it "cleans up order" do
          expect(updater).to have_received(:clean_up).with(july_account_invoice.order, anything).once
        end
      end
    end

    describe "clean_up" do
      let!(:invoice_order) { create(:order) }
      let!(:obsolete1) { create(:adjustment, adjustable: invoice_order) }
      let!(:obsolete2) { create(:adjustment, adjustable: invoice_order) }
      let!(:current1) { create(:adjustment, adjustable: invoice_order) }
      let!(:current2) { create(:adjustment, adjustable: invoice_order) }

      before do
        allow(invoice_order).to receive(:save)
        allow(invoice_order).to receive(:destroy)
        allow(Bugsnag).to receive(:notify)
      end

      context "when current adjustments are present" do
        let!(:current_adjustments) { [current1, current2] }

        context "and obsolete adjustments are present" do
          let!(:obsolete_adjustments) { [obsolete1, obsolete2] }

          before do
            allow(obsolete_adjustments).to receive(:destroy_all)
            allow(invoice_order).to receive(:adjustments) { double(:adjustments, where: obsolete_adjustments) }
            updater.clean_up(invoice_order, current_adjustments)
          end

          it "destroys obsolete adjustments and snags a bug" do
            expect(obsolete_adjustments).to have_received(:destroy_all)
            expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("Obsolete Adjustments"), anything)
          end
        end

        context "and obsolete adjustments are not present" do
          let!(:obsolete_adjustments) { [] }

          before do
            allow(invoice_order).to receive(:adjustments) { double(:adjustments, where: obsolete_adjustments) }
            updater.clean_up(invoice_order, current_adjustments)
          end

          it "has no bugs to snag" do
            expect(Bugsnag).to_not have_received(:notify)
          end
        end
      end

      context "when current adjustments are not present" do
        let!(:current_adjustments) { [] }

        context "and obsolete adjustments are present" do
          let!(:obsolete_adjustments) { [obsolete1, obsolete2] }

          before do
            allow(obsolete_adjustments).to receive(:destroy_all)
            allow(invoice_order).to receive(:adjustments) { double(:adjustments, where: obsolete_adjustments) }
          end

          it "destroys obsolete adjustments and snags a bug" do
            updater.clean_up(invoice_order, current_adjustments)
            expect(obsolete_adjustments).to have_received(:destroy_all)
            expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("Obsolete Adjustments"), anything)
          end

          context "when the order is not persisted" do
            before do
              allow(invoice_order).to receive(:persisted?) { false }
            end

            it "destroys the order" do
              updater.clean_up(invoice_order, current_adjustments)
              expect(invoice_order).to have_received(:destroy)
            end
          end

          context "when the order is persisted" do
            before do
              allow(invoice_order).to receive(:persisted?) { true }
            end

            it "snags a bug" do
              updater.clean_up(invoice_order, current_adjustments)
              expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("Empty Persisted Invoice"), anything)
            end
          end
        end

        context "and obsolete adjustments are not present" do
          let!(:obsolete_adjustments) { [] }

          before do
            allow(invoice_order).to receive(:adjustments) { double(:adjustments, where: obsolete_adjustments) }
          end

          it "has no bugs to snag" do
            expect(Bugsnag).to_not have_received(:notify).with(RuntimeError.new("Obsolete Adjustments"), anything)
          end

          context "when the order is not persisted" do
            before do
              allow(invoice_order).to receive(:persisted?) { false }
            end

            it "destroys the order" do
              updater.clean_up(invoice_order, current_adjustments)
              expect(invoice_order).to have_received(:destroy)
            end
          end

          context "when the order is persisted" do
            before do
              allow(invoice_order).to receive(:persisted?) { true }
            end

            it "snags a bug" do
              updater.clean_up(invoice_order, current_adjustments)
              expect(Bugsnag).to have_received(:notify).with(RuntimeError.new("Empty Persisted Invoice"), anything)
            end
          end
        end
      end
    end
  end

  describe "validation spec" do
    let!(:start_of_july) { Time.zone.local(year, 7) }

    let!(:updater) { UpdateAccountInvoices.new }

    let!(:accounts_distributor) { create(:distributor_enterprise) }

    let!(:user) { create(:user) }
    let!(:july_billable_period1) { create(:billable_period, sells: 'any', owner: user, begins_at: start_of_july - 1.month, ends_at: start_of_july) }
    let!(:july_billable_period2) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 10.days) }
    let!(:july_billable_period3) { create(:billable_period, owner: user, begins_at: start_of_july + 12.days, ends_at: start_of_july + 20.days) }
    let!(:july_account_invoice) { july_billable_period2.account_invoice }
    let!(:august_account_invoice) { create(:account_invoice, user: user, year: july_account_invoice.year, month: 8)}

    before do
      Spree::Config.set({ accounts_distributor_id: accounts_distributor.id })
      july_billable_period2.enterprise.update_attributes(contact: 'Anna Karenina', phone: '3433523')
    end

    context "when no invoice_order currently exists" do
      context "when relevant billable periods exist" do
        travel_to(20.days)

        it "creates an invoice_order" do
          expect{updater.perform}.to change{Spree::Order.count}.from(0).to(1)
          invoice_order = july_account_invoice.reload.order
          expect(user.orders.first).to eq invoice_order
          expect(invoice_order.completed_at).to be_nil
          billable_adjustments = invoice_order.adjustments.where('source_type = (?)', 'BillablePeriod')
          expect(billable_adjustments.map(&:amount)).to eq [july_billable_period2.bill.round(2), july_billable_period3.bill.round(2)]
          expect(invoice_order.total).to eq july_billable_period2.bill.round(2) + july_billable_period3.bill.round(2)
          expect(invoice_order.payments.count).to eq 0
          expect(invoice_order.state).to eq 'cart'
          expect(invoice_order.bill_address).to be_a Spree::Address
          expect(invoice_order.ship_address).to be_a Spree::Address
          expect(invoice_order.shipping_address).to eq invoice_order.billing_address
          [:address1, :address2, :city, :zipcode, :state_id, :country_id].each do |attr|
            expect(invoice_order.billing_address[attr]).to eq july_billable_period2.enterprise.address[attr]
          end
          expect(invoice_order.billing_address.firstname).to eq "Anna"
          expect(invoice_order.billing_address.lastname).to eq "Karenina"
          expect(invoice_order.billing_address.phone).to eq "3433523"
        end
      end

      context "when no relevant billable periods exist" do
        travel_to(1.month + 5.days)

        it "does not create an order" do
          expect(updater).to receive(:update).with(august_account_invoice).and_call_original
          expect{updater.perform}.to_not change{Spree::Order.count}.from(0)
        end
      end
    end

    context "when an order already exists" do
      context "when relevant billable periods exist" do
        let!(:invoice_order) { create(:order, user: user, distributor: accounts_distributor, created_at: start_of_july) }
        let!(:billable_adjustment) { create(:adjustment, adjustable: invoice_order, source_type: 'BillablePeriod') }

        before do
          invoice_order.line_items.clear
          july_account_invoice.update_attribute(:order, invoice_order)
        end

        travel_to(20.days)

        it "updates the order, and clears any obsolete invoices" do
          expect{updater.perform}.to_not change{Spree::Order.count}
          invoice_order = user.orders.first
          expect(invoice_order.completed_at).to be_nil
          billable_adjustments = invoice_order.adjustments.where('source_type = (?)', 'BillablePeriod')
          expect(billable_adjustments).to_not include billable_adjustment
          expect(billable_adjustments.map(&:amount)).to eq [july_billable_period2.bill.round(2), july_billable_period3.bill.round(2)]
          expect(invoice_order.total).to eq july_billable_period2.bill.round(2) + july_billable_period3.bill.round(2)
          expect(invoice_order.payments.count).to eq 0
          expect(invoice_order.state).to eq 'cart'
          expect(invoice_order.bill_address).to be_a Spree::Address
          expect(invoice_order.ship_address).to be_a Spree::Address
          expect(invoice_order.shipping_address).to eq invoice_order.billing_address
          [:address1, :address2, :city, :zipcode, :state_id, :country_id].each do |attr|
            expect(invoice_order.billing_address[attr]).to eq july_billable_period2.enterprise.address[attr]
          end
          expect(invoice_order.billing_address.firstname).to eq "Anna"
          expect(invoice_order.billing_address.lastname).to eq "Karenina"
          expect(invoice_order.billing_address.phone).to eq "3433523"
        end
      end

      context "when no relevant billable periods exist" do
        let!(:invoice_order) { create(:order, user: user, distributor: accounts_distributor) }

        before do
          invoice_order.line_items.clear
          august_account_invoice.update_attribute(:order, invoice_order)
        end

        travel_to(1.month + 5.days)

        it "snags a bug" do
          expect(updater).to receive(:update).with(august_account_invoice).and_call_original
          expect(Bugsnag).to receive(:notify).with(RuntimeError.new("Empty Persisted Invoice"), anything)
          expect{updater.perform}.to_not change{Spree::Order.count}
        end
      end
    end
  end
end
