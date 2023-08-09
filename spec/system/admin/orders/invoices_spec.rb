# frozen_string_literal: true

require 'system_helper'

describe '
 As an administrator
 I want to manage invoices for an order
' do
  include WebHelper
  include AuthenticationHelper

  let(:user) { create(:user) }
  let(:product) { create(:simple_product) }
  let(:distributor) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor],
                                variants: [product.variants.first])
  end

  let(:order) do
    create(:order_with_totals_and_distribution,
           distributor:, user:,
           order_cycle:, state: 'complete',
           payment_state: 'balance_due')
  end
  let(:customer) { order.customer }

  before do
    Flipper.enable(:invoices)
    order.finalize!
    login_as_admin
    visit spree.edit_admin_order_path(order)
  end

  describe 'creating invoices' do
    context 'when the order has no invoices' do
      it 'creates an invoice for the order' do
        click_link 'Invoices'

        expect {
          click_link "Create or Update Invoice"
          expect(page).to have_no_link "Create or Update Invoice"
        }.to change { order.invoices.count }.by(1)

        invoice = order.invoices.first
        expect(invoice.cancelled).to eq false
        expect(invoice.number).to eq 1
      end
    end

    context 'when the order has an invoice' do
      let!(:latest_invoice){ create(:invoice, order:, number: 1, cancelled: false) }

      context 'order not updated since latest invoice' do
        it 'should not render new invoice button' do
          click_link 'Invoices'
          expect(page).to_not have_link "Create or Update Invoice"
        end
      end

      # For reference check:
      # https://docs.google.com/spreadsheets/d/1hOM6UL4mWeRCFLcDQ3fTkbhbUQ2WvIUCCA1IerDBtUA/edit#gid=0
      context 'order updated since latest invoice' do
        context 'changes require regenerating' do
          let(:new_note){ 'new note' }
          before do
            order.update!(note: new_note)
          end

          it 'updates the lastest invoice for the order' do
            click_link 'Invoices'
            expect {
              click_link "Create or Update Invoice"
              expect(page).to have_no_link "Create or Update Invoice"
            }.to change { order.reload.invoices.count }.by(0)
              .and change { latest_invoice.reload.presenter.note }.from("").to(new_note)

            expect(latest_invoice.reload.cancelled).to eq false
          end
        end

        context 'changes require generating a new invoice' do
          before do
            order.line_items.first.update!(quantity: 2)
          end

          it 'creates a new invoice for the order' do
            click_link 'Invoices'
            expect {
              click_link "Create or Update Invoice"
              expect(page).to have_no_link "Create or Update Invoice"
            }.to change { order.reload.invoices.count }.by(1)

            expect(latest_invoice.reload.cancelled).to eq true
            expect(latest_invoice.presenter.sorted_line_items.first.quantity).to eq 1

            new_invoice = order.invoices.first # first invoice is the latest
            expect(new_invoice.cancelled).to eq false
            expect(new_invoice.number).to eq 2
            expect(new_invoice.presenter.sorted_line_items.first.quantity).to eq 2
          end
        end
      end
    end
  end

  describe 'listing invoices' do
    let(:date){ Time.current.to_date }

    let(:row1){
      [
        I18n.l(date, format: :long),
        "2",
        order.total,
        "Active",
        "Download"
      ].join(" ")
    }

    let(:row2){
      [
        I18n.l(date, format: :long),
        "1",
        order.total,
        "Cancelled",
        "Download"
      ].join(" ")
    }

    let(:table_content){
      [
        row1,
        row2
      ].join(" ")
    }

    before do
      create(:invoice, order:, number: 1, cancelled: true, date:)
      create(:invoice, order:, number: 2, cancelled: false, date:)
    end

    it 'should list the invoices on the reverse order of creation' do
      click_link 'Invoices'
      expect(page).to have_content table_content
    end
  end
end
