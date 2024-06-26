# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
 As an administrator
 I want to manage invoices for an order
', feature: :invoices do
  include WebHelper
  include AuthenticationHelper

  let(:user) { create(:user) }
  let(:product) { create(:simple_product) }
  let(:distributor) {
    create(:distributor_enterprise, owner: user, charges_sales_tax: true, abn: "123456")
  }
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
          expect(page).not_to have_link "Create or Update Invoice"
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
          expect(page).not_to have_link "Create or Update Invoice"
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
              expect(page).not_to have_link "Create or Update Invoice"
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
              expect(page).not_to have_link "Create or Update Invoice"
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

  describe 'printing invoices' do
    context 'when the order has no invoices' do
      it 'creates an invoice for the order' do
        expect(order.invoices.count).to eq 0
        page.find("#links-dropdown", text: "Actions").click
        click_link "Print Invoice"
        # wait for PDF to open in new window
        new_window = windows.last
        page.within_window new_window do
          expect(order.invoices.count).to eq 1
        end
        invoice = order.invoices.first
        expect(invoice.cancelled).to eq false
        expect(invoice.number).to eq 1
      end
    end

    context 'when the order has an invoice' do
      let!(:latest_invoice){ create(:invoice, order:, number: 1, cancelled: false) }
      context 'changes require regenerating' do
        let(:new_note){ 'new note' }
        before do
          order.update!(note: new_note)
        end

        it 'updates the lastest invoice for the order' do
          expect(order.invoices.count).to eq 1
          page.find("#links-dropdown", text: "Actions").click
          click_link "Print Invoice"
          new_window = windows.last
          page.within_window new_window do
            expect(order.invoices.count).to eq 1
          end
          expect(latest_invoice.reload.presenter.note).to eq new_note
          expect(latest_invoice.reload.cancelled).to eq false
        end
      end
      context 'changes require generating a new invoice' do
        before do
          order.line_items.first.update!(quantity: 2)
        end

        it 'creates a new invoice for the order' do
          expect(order.invoices.count).to eq 1
          page.find("#links-dropdown", text: "Actions").click
          click_link "Print Invoice"
          new_window = windows.last
          page.within_window new_window do
            expect(order.invoices.count).to eq 2
          end
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

  describe 'listing invoices' do
    let(:date){ Time.current.to_date }

    let(:first_invoice){ "#{distributor.id}-1" }
    let(:second_invoice){ "#{distributor.id}-2" }

    let(:row1){
      [
        I18n.l(date, format: :long),
        second_invoice,
        order.total,
        "Active",
        "Download"
      ].join(" ")
    }

    let(:row2){
      [
        I18n.l(date, format: :long),
        first_invoice,
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

RSpec.describe "Invoice order states", feature: :invoices do
  let(:user) { create(:user) }
  let(:product) { create(:simple_product) }
  let(:distributor) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor],
                                variants: [product.variants.first])
  end
  let(:order) do
    create(:order_with_totals_and_distribution, user:, distributor:,
                                                order_cycle:, state: 'complete',
                                                payment_state: 'balance_due')
  end
  let(:customer) { order.customer }

  before do
    order.finalize!

    login_as user
  end

  context "complete" do
    let!(:order1) {
      create(:order_with_totals_and_distribution, user:, distributor:,
                                                  order_cycle:, state: 'complete',
                                                  payment_state: 'balance_due',
                                                  customer_id: customer.id)
    }

    context "editing the order" do
      before do
        visit spree.edit_admin_order_path(order1)
      end

      it "displays the invoice tab" do
        expect(page).to have_content "Complete".upcase
        expect(page).to have_content "Invoices".upcase
      end
    end

    context "visiting the invoices tab" do
      let!(:table_header) {
        [
          "Date/Time",
          "Invoice Number",
          "Amount",
          "Status",
          "File",
        ].join(" ")
      }

      let(:invoice_number){ "#{order.distributor_id}-1" }
      let(:table_contents) {
        [
          Invoice.first.created_at.strftime('%B %d, %Y').to_s,
          invoice_number,
          "0.0",
          "Active",
          "Download"
        ].join(" ")
      }
      let(:download_href) {
        "#{spree.print_admin_order_path(order1)}?invoice_id=#{Invoice.last.id}"
      }

      before do
        Spree::Config[:enterprise_number_required_on_invoices?] = false
        visit spree.admin_order_invoices_path(order1)
      end

      it "displays the invoices table" do
        # with no invoices, only the table header is displayed
        expect(page).to have_css "table.index"
        expect(page).to have_content "#{customer.first_name} #{customer.last_name} -"
        expect(page.find("table").text).to have_content(table_header)

        # the New invoice button + the warning should be visible
        expect(page).to have_link "Create or Update Invoice"
        expect(page).to have_content "The order has changed since the last invoice update."
        click_link "Create or Update Invoice"

        # and disappear after clicking
        expect(page).not_to have_link "Create or Update Invoice"
        expect(page).not_to have_content "The order has changed since the last invoice update."

        # creating an invoice, displays a second row
        expect(page.find("table").text).to have_content(table_contents)

        # with a valid invoice download link
        expect(page).to have_link("Download",
                                  href: download_href)
      end

      context "the Create or Update Invoice button" do
        context "when an ABN number is mandatory for invoices but not present" do
          before do
            Spree::Config[:enterprise_number_required_on_invoices?] = true
          end

          it "displays a warning that an ABN is required when it's clicked" do
            visit spree.admin_order_invoices_path(order1)
            message = accept_prompt { click_link "Create or Update Invoice" }
            distributor = order1.distributor
            expect(message)
              .to eq "#{distributor.name} must have a valid ABN before invoices can be used."
          end
        end
      end
    end
  end

  context "resumed" do
    let!(:order2) {
      create(:order_with_totals_and_distribution, user:, distributor:,
                                                  order_cycle:, state: 'resumed',
                                                  payment_state: 'balance_due')
    }
    before do
      visit spree.edit_admin_order_path(order2)
    end

    it "displays the invoice tab" do
      expect(page).to have_content "Resumed".upcase
      expect(page).to have_content "Invoices".upcase
    end
  end

  context "canceled" do
    let!(:order3) {
      create(:order_with_totals_and_distribution, user:, distributor:,
                                                  order_cycle:, state: 'canceled',
                                                  payment_state: 'balance_due')
    }
    before do
      visit spree.edit_admin_order_path(order3)
    end

    it "displays the invoice tab" do
      expect(page).to have_content "Cancelled".upcase
      expect(page).to have_content "Invoices".upcase
    end
  end

  context "cart" do
    let!(:order_empty) {
      create(:order_with_line_items, user:, distributor:, order_cycle:,
                                     line_items_count: 0)
    }
    before do
      visit spree.edit_admin_order_path(order_empty)
    end

    it "should not display the invoice tab" do
      expect(page).to have_content "Cart".upcase
      expect(page).not_to have_content "Invoices".upcase
    end
  end

  context "payment" do
    let!(:order4) do
      create(:order_ready_for_payment, user:, distributor:,
                                       order_cycle:,
                                       payment_state: 'balance_due')
    end
    before do
      visit spree.edit_admin_order_path(order4)
    end

    it "should not display the invoice tab" do
      expect(page).to have_content "Payment".upcase
      expect(page).not_to have_content "Invoices".upcase
    end
  end
end
