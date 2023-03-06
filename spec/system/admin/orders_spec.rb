# frozen_string_literal: true

require "system_helper"

describe '
    As an administrator
    I want to manage orders
' do
  include AuthenticationHelper
  include WebHelper

  let(:owner) { create(:user) }
  let(:owner2) { create(:user) }
  let(:customer) { create(:user) }
  let(:customer2) { create(:user) }
  let(:customer3) { create(:user) }
  let(:customer4) { create(:user) }
  let(:customer5) { create(:user) }
  let(:billing_address) { create(:address, :randomized) }
  let(:billing_address2) { create(:address, :randomized) }
  let(:billing_address3) { create(:address, :randomized) }
  let(:billing_address4) { create(:address, :randomized) }
  let(:billing_address5) { create(:address, :randomized) }
  let(:product) { create(:simple_product) }
  let(:distributor) { create(:distributor_enterprise, owner: owner, with_payment_and_shipping: true, charges_sales_tax: true) }
  let(:distributor2) { create(:distributor_enterprise_with_tax, owner: owner) }
  let(:distributor3) { create(:distributor_enterprise, owner: owner, with_payment_and_shipping: true, charges_sales_tax: true) }
  let(:distributor4) { create(:distributor_enterprise, owner: owner, with_payment_and_shipping: true, charges_sales_tax: true) }
  let(:distributor5) { create(:distributor_enterprise, owner: owner2, charges_sales_tax: true) }
  let!(:shipping_method) { create(:shipping_method_with, :pickup, name: "pick_up", distributors: [distributor, distributor2, distributor3]) }
  let!(:shipping_method2) { create(:shipping_method_with, :pickup, name: "delivery", distributors: [distributor4, distributor5]) }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor, distributor2, distributor3, distributor4],
                                variants: [product.variants.first])
  end

  context "with a complete order" do
    let(:order) do
      create(:order_with_totals_and_distribution, user: customer, distributor: distributor,
                                                  order_cycle: order_cycle,
                                                  state: 'complete', payment_state: 'balance_due',
                                                  bill_address_id: billing_address.id)
    end

    let!(:order_cycle2) {
      create(:simple_order_cycle, name: 'Two', orders_close_at: 2.weeks.from_now)
    }
    let!(:order_cycle3) {
      create(:simple_order_cycle, name: 'Three', orders_close_at: 3.weeks.from_now)
    }
    let!(:order_cycle4) {
      create(:simple_order_cycle, name: 'Four', orders_close_at: 4.weeks.from_now)
    }
    let!(:order_cycle5) do
      create(:simple_order_cycle, name: 'Five', coordinator: distributor5, distributors: [distributor5],
                                  variants: [product.variants.first])
    end

    let!(:order2) {
      create(:order_ready_to_ship, user: customer2, distributor: distributor2,
                                   order_cycle: order_cycle2, completed_at: 2.days.ago,
                                   bill_address_id: billing_address2.id)
    }
    let!(:order3) {
      create(:order_with_credit_payment, user: customer3, distributor: distributor3,
                                         order_cycle: order_cycle3,
                                         bill_address_id: billing_address3.id)
    }
    let!(:order4) {
      create(:order_with_credit_payment, user: customer4, distributor: distributor4,
                                         order_cycle: order_cycle4,
                                         bill_address_id: billing_address4.id)
    }
    let!(:order5) {
      create(:order_ready_to_ship, user: customer5, distributor: distributor5,
                                   order_cycle: order_cycle5,
                                   bill_address_id: billing_address5.id)
    }

    context "logging as superadmin and visiting the orders page" do
      before do
        order2.select_shipping_method(shipping_method.id)
        order4.select_shipping_method(shipping_method2.id)
        login_as_admin_and_visit spree.admin_orders_path
      end

      context "fiters" do
        it "order cycles appear in descending order by close date on orders page" do
          open_select2('#s2id_q_order_cycle_id_in')

          expect(find('#q_order_cycle_id_in',
                      visible: :all)[:innerHTML]).to have_content(/.*Four.*Three.*Two.*Five/m)
        end

        it "filter by multiple order cycles" do
          select2_select 'Two', from: 'q_order_cycle_id_in'
          select2_select 'Three', from: 'q_order_cycle_id_in'

          page.find('.filter-actions .button.icon-search').click

          # Order 2 and 3 should show, but not 4
          expect(page).to have_content order2.number
          expect(page).to have_content order3.number
          expect(page).to_not have_content order4.number
        end

        it "filter by distributors" do
          select2_select distributor2.name.to_s, from: 'q_distributor_id_in'
          select2_select distributor4.name.to_s, from: 'q_distributor_id_in'

          page.find('.filter-actions .button.icon-search').click

          # Order 2 and 4 should show, but not 3
          expect(page).to have_content order2.number
          expect(page).to_not have_content order3.number
          expect(page).to have_content order4.number
        end

        it "filter by complete date" do
          find("input.datepicker").click
          select_dates_from_daterangepicker(order3.completed_at.yesterday, order4.completed_at.tomorrow)

          page.find('.filter-actions .button.icon-search').click

          # Order 3 and 4 should show, but not 2
          expect(page).to_not have_content order2.number
          expect(page).to have_content order3.number
          expect(page).to have_content order4.number
        end

        it "filter by email" do
          fill_in "Email", with: customer3.email

          page.find('.filter-actions .button.icon-search').click

          # Order 3 should show, but not 2 and 4
          expect(page).to_not have_content order2.number
          expect(page).to have_content order3.number
          expect(page).to_not have_content order4.number
        end

        it "filter by customer first and last names" do
          # NOTE: this field refers to the name given in billing addresses and not to customer name
          # filtering by first name
          fill_in "First name begins with", with: billing_address2.firstname
          page.find('.filter-actions .button.icon-search').click
          # Order 3 should show, but not 2 and 4
          expect(page).to have_content order2.number
          expect(page).to_not have_content order3.number
          expect(page).to_not have_content order4.number

          find("a#clear_filters_button").click
          # filtering by last name

          fill_in "Last name begins with", with: billing_address4.lastname
          page.find('.filter-actions .button.icon-search').click
          # Order 4 should show, but not 2 and 3
          expect(page).to_not have_content order2.number
          expect(page).to_not have_content order3.number
          expect(page).to have_content order4.number
        end

        it "filter by shipping methods" do
          select2_select "Pick-up at the farm", from: 'q_shipping_method_id'
          page.find('.filter-actions .button.icon-search').click
          # Order 2 should show, but not 3 and 5
          expect(page).to have_content order2.number
          expect(page).to_not have_content order3.number
          expect(page).to_not have_content order4.number

          find("a#clear_filters_button").click

          select2_select "Signed, sealed, delivered", from: 'q_shipping_method_id'
          page.find('.filter-actions .button.icon-search').click
          # Order 4 should show, but not 2 and 3
          expect(page).to_not have_content order2.number
          expect(page).to_not have_content order3.number
          expect(page).to have_content order4.number
        end

        it "filter by invoice number" do
          fill_in "Invoice number:", with: order2.number

          page.find('.filter-actions .button.icon-search').click

          # Order 2 should show, but not 3 and 4
          expect(page).to have_content order2.number
          expect(page).to_not have_content order3.number
          expect(page).to_not have_content order4.number
        end

        it "filter by order state" do
          order.update(state: "payment")

          uncheck 'Only show complete orders'
          page.find('.filter-actions .button.icon-search').click

          expect(page).to have_content order.number
          expect(page).to have_content order2.number
          expect(page).to have_content order3.number
          expect(page).to have_content order4.number
          expect(page).to have_content order5.number

          select2_select "payment", from: 'q_state_eq'

          page.find('.filter-actions .button.icon-search').click

          # Order 2 should show, but not 3 and 4
          expect(page).to have_content order.number
          expect(page).to_not have_content order2.number
          expect(page).to_not have_content order3.number
          expect(page).to_not have_content order4.number
          expect(page).to_not have_content order5.number
        end
      end

      context "ordering" do
        context "orders with different completion dates" do
          before do
            order2.update!(completed_at: Time.zone.now - 2.weeks)
            order3.update!(completed_at: Time.zone.now - 3.weeks)
            order4.update!(completed_at: Time.zone.now - 4.weeks)
            order5.update!(completed_at: Time.zone.now - 5.weeks)
            login_as_admin_and_visit spree.admin_orders_path
          end
          it "orders by completion date" do
            find("a", text: 'COMPLETED AT').click # sets ascending ordering
            expect(page).to have_content(/#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m)
            find("a", text: 'COMPLETED AT').click # sets descending ordering
            expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m)
          end
        end

        context "orders with different order numbers" do
          before do
            order2.update!(number: "R555555555")
            order3.update!(number: "R444444444")
            order4.update!(number: "R333333333")
            order5.update!(number: "R222222222")
            login_as_admin_and_visit spree.admin_orders_path
          end

          it "orders by order number" do
            find("a", text: 'NUMBER').click # sets ascending ordering
            expect(page).to have_content(/#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m)
            find("a", text: 'NUMBER').click # sets descending ordering
            expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m)
          end
        end

        context "orders with different states" do
          before do
            order2.update!(state: "payment")
            order3.update!(state: "complete")
            order4.update!(state: "cart")
            order5.cancel
            login_as_admin_and_visit spree.admin_orders_path
            uncheck 'Only show complete orders'
            page.find('.filter-actions .button.icon-search').click
          end

          it "orders by order state" do
            find("a", text: 'STATE').click # sets ascending ordering
            expect(page).to have_content(/#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m)
            find("a", text: 'STATE').click # sets descending ordering
            expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m)
          end
        end

        context "orders with different payment states" do
          before do
            Spree::Payment.where(order_id: order2.id).first.update!(amount: 50.0)
            Spree::Payment.where(order_id: order3.id).first.update!(amount: 100.0)
            Spree::Payment.where(order_id: order4.id).first.update!(amount: 10.0)
            login_as_admin_and_visit spree.admin_orders_path
          end

          it "orders by payment state" do
            find("a", text: 'PAYMENT STATE').click # sets ascending ordering
            expect(page).to have_content(/#{order4.number}.*#{order3.number}.*#{order2.number}/m)
            find("a", text: 'PAYMENT STATE').click # sets descending ordering
            expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}/m)
          end
        end

        context "orders with different shipment states" do
          before do
            Spree::Payment.where(order_id: order2.id).first.update!(amount: 50.0)
            Spree::Payment.where(order_id: order3.id).first.update!(amount: 100.0)
            Spree::Payment.where(order_id: order4.id).first.update!(amount: 10.0)
            order2.ship
            login_as_admin_and_visit spree.admin_orders_path
          end

          it "orders by shipment state" do
            find("a", text: 'SHIPMENT STATE').click # sets ascending ordering
            expect(page).to have_content(/#{order4.number}.*#{order3.number}.*#{order2.number}/m)
            find("a", text: 'SHIPMENT STATE').click # sets descending ordering
            expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}/m)
          end
        end

        context "orders from different customers" do
          before do
            order2.update!(email: "jkl@jkl.com")
            order3.update!(email: "ghi@ghi.com")
            order4.update!(email: "def@def.com")
            order5.update!(email: "abc@abc.com")
            login_as_admin_and_visit spree.admin_orders_path
          end

          it "orders by customer email" do
            find("a", text: 'EMAIL').click # sets ascending ordering
            expect(page).to have_content(/#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m)
            find("a", text: 'EMAIL').click # sets descending ordering
            expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m)
          end
        end

        context "orders with different billing addresses" do
          before do
            billing_address2.update!(lastname: "Mad Hatter")
            billing_address3.update!(lastname: "Duchess")
            billing_address4.update!(lastname: "Cheshire Cat")
            billing_address5.update!(lastname: "Alice")
            login_as_admin_and_visit spree.admin_orders_path
          end

          it "orders by last name" do
            find("a", text: 'NAME').click # sets ascending ordering
            expect(page).to have_content(/#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m)
            find("a", text: 'NAME').click # sets descending ordering
            expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m)
          end
        end

        context "orders with different order totals" do
          before do
            Spree::LineItem.where(order_id: order2.id).first.update!(quantity: 5)
            Spree::LineItem.where(order_id: order3.id).first.update!(quantity: 4)
            Spree::LineItem.where(order_id: order4.id).first.update!(quantity: 3)
            Spree::LineItem.where(order_id: order5.id).first.update!(quantity: 2)
            order2.save
            order3.save
            order4.save
            order5.save
            login_as_admin_and_visit spree.admin_orders_path
          end

          it "orders by order total" do
            find("a", text: 'TOTAL').click # sets ascending ordering
            expect(page).to have_content(/#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m)
            find("a", text: 'TOTAL').click # sets descending ordering
            expect(page).to have_content(/#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m)
          end
        end
      end
    end

    context "select/unselect all orders" do
      before do
        login_as_admin_and_visit spree.admin_orders_path
      end

      it "by clicking on the checkbox in the table header" do
        # select all orders
        page.find("#listing_orders thead th:first-child input[type=checkbox]").click
        expect(page.find("#listing_orders tbody tr td:first-child input[type=checkbox]")).to be_checked
        # enables print invoices button
        page.find("span.icon-reorder", text: "ACTIONS").click
        expect(page).to have_content "Print Invoices"
        # unselect all orders
        page.find("#listing_orders thead th:first-child input[type=checkbox]").click
        expect(page.find("#listing_orders tbody tr td:first-child input[type=checkbox]")).to_not be_checked
        # disables print invoices button
        page.find("span.icon-reorder", text: "ACTIONS").click
        expect(page).to_not have_content "Print Invoices"
      end
    end

    context "bulk actions" do
      context "resend confirmation email" do
        it "can bulk send email to 2 orders" do
          login_as_admin_and_visit spree.admin_orders_path

          page.find("#listing_orders tbody tr:nth-child(1) input[name='order_ids[]']").click
          page.find("#listing_orders tbody tr:nth-child(2) input[name='order_ids[]']").click

          page.find("span.icon-reorder", text: "ACTIONS").click
          within ".ofn-drop-down-with-prepend .menu" do
            page.find("span", text: "Resend Confirmation").click
          end

          expect(page).to have_content "Are you sure you want to proceed?"

          within ".reveal-modal" do
            expect {
              find_button("Confirm").click
            }.to enqueue_job(ActionMailer::MailDeliveryJob).exactly(:twice)
          end

          expect(page).to have_content "Confirmation emails sent for 2 orders."
        end

        it "can bulk print invoices from 2 orders" do
          login_as_admin_and_visit spree.admin_orders_path

          page.find("#listing_orders tbody tr:nth-child(1) input[name='order_ids[]']").click
          page.find("#listing_orders tbody tr:nth-child(2) input[name='order_ids[]']").click

          page.find("span.icon-reorder", text: "ACTIONS").click
          within ".ofn-drop-down-with-prepend .menu" do
            page.find("span", text: "Print Invoices").click
          end

          expect(page).to have_content "Compiling Invoices"
          expect(page).to have_content "Please wait until the PDF is ready before closing this modal."
          # an error 422 is generated in the console
        end

        it "can bulk cancel 2 orders" do
          login_as_admin_and_visit spree.admin_orders_path

          page.find("#listing_orders tbody tr:nth-child(1) input[name='order_ids[]']").click
          page.find("#listing_orders tbody tr:nth-child(2) input[name='order_ids[]']").click

          page.find("span.icon-reorder", text: "ACTIONS").click
          within ".ofn-drop-down-with-prepend .menu" do
            page.find("span", text: "Cancel Orders").click
          end

          expect(page).to have_content "Are you sure you want to proceed?"
          expect(page).to have_content "This will cancel the current order."

          within ".reveal-modal" do
            expect {
              find_button("Cancel").click # Cancels the cancel action
            }.to_not enqueue_job(ActionMailer::MailDeliveryJob).exactly(:twice)
          end

          page.find("span.icon-reorder", text: "ACTIONS").click
          within ".ofn-drop-down-with-prepend .menu" do
            page.find("span", text: "Cancel Orders").click
          end

          within ".reveal-modal" do
            expect {
              find_button("Confirm").click # Confirms the cancel action
            }.to_not enqueue_job(ActionMailer::MailDeliveryJob).exactly(:twice)
          end

          expect(page).to have_content("CANCELLED", count: 2)
        end

        context "for a hub manager" do
          before do
            login_to_admin_as owner2
            visit spree.admin_orders_path
          end

          it "displays the orders for the respective distributor" do
            expect(page).to have_content order5.number # displays the only order for distributor5
            expect(page).not_to have_content order.number
            expect(page).not_to have_content order2.number
            expect(page).not_to have_content order3.number
            expect(page).not_to have_content order4.number
          end

          it "cannot send emails to orders if permission have been revoked in the meantime" do
            page.find("#listing_orders tbody tr:nth-child(1) input[name='order_ids[]']").click
            # Find the clicked order
            order = Spree::Order.find_by(id: page.find("#listing_orders tbody tr:nth-child(1) input[name='order_ids[]']").value)
            # Revoke permission for the current user on that specific order by changing its owners
            order.update_attribute(:distributor, distributor)
            order.update_attribute(:order_cycle, order_cycle)

            page.find("span.icon-reorder", text: "ACTIONS").click
            within ".ofn-drop-down-with-prepend .menu" do
              page.find("span", text: "Resend Confirmation").click
            end

            expect(page).to have_content "Are you sure you want to proceed?"

            within ".reveal-modal" do
              expect {
                find_button("Confirm").click
              }.to_not enqueue_job(ActionMailer::MailDeliveryJob)
            end
          end
        end
      end
    end

    context "pagination" do
      before do
        login_as_admin_and_visit spree.admin_orders_path
      end

      it "displays pagination options" do
        # displaying 4 orders (one order per table row)
        within('tbody') do
          expect(page).to have_css('tr.ng-scope', count: 4)
        end
        # pagination options also refer 4 order
        expect(page).to have_content "4 Results found. Viewing 1 to 4."
        page.find(".per-page-select").click # toggling the pagination dropdown
        expect(page).to have_content "15 per page"
        expect(page).to have_content "50 per page"
        expect(page).to have_content "100 per page"
      end
    end

    context "with a capturable order" do
      before do
        order.finalize! # ensure order has a payment to capture
        order.payments << create(:check_payment, order: order, amount: order.total)
      end

      it "capture payment" do
        login_as_admin_and_visit spree.admin_orders_path
        expect(page).to have_current_path spree.admin_orders_path

        # click the 'capture' link for the order
        page.find("[data-powertip=Capture]").click

        expect(page).to have_css "i.success"
        expect(page).to have_css "button.icon-road"

        # check the order was captured
        expect(order.reload.payment_state).to eq "paid"

        # we should still be on the same page
        expect(page).to have_current_path spree.admin_orders_path
      end

      it "ship order from the orders index page" do
        order.payments.first.capture!
        login_as_admin_and_visit spree.admin_orders_path

        page.find("[data-powertip=Ship]").click

        expect(page).to have_css "i.success"
        expect(order.reload.shipments.any?(&:shipped?)).to be true
        expect(order.shipment_state).to eq("shipped")
      end
    end
  end

  context "with incomplete order" do
    it "can edit order" do
      incomplete_order = create(:order_with_line_items, distributor: distributor,
                                                        order_cycle: order_cycle, line_items_count: 1)

      login_as_admin_and_visit spree.admin_orders_path
      uncheck 'Only show complete orders'
      page.find('a.icon-search').click

      find(".icon-edit").click

      expect(page).to have_current_path spree.edit_admin_order_path(incomplete_order)
    end
  end

  context "test the 'Only show the complete orders' checkbox" do
    it "display or not incomplete order" do
      incomplete_order = create(:order_with_line_items, distributor: distributor,
                                                        order_cycle: order_cycle, line_items_count: 1)
      complete_order = create(
        :order_with_line_items,
        distributor: distributor,
        order_cycle: order_cycle,
        user: customer,
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago,
        line_items_count: 1
      )

      empty_complete_order = create(
        :order_with_line_items,
        distributor: distributor,
        order_cycle: order_cycle,
        user: customer,
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago,
        line_items_count: 0
      )

      empty_order = create(:order, distributor: distributor, order_cycle: order_cycle)

      login_as_admin_and_visit spree.admin_orders_path
      expect(page).to have_content complete_order.number
      expect(page).to have_content empty_complete_order.number
      expect(page).to have_no_content incomplete_order.number
      expect(page).to have_no_content empty_order.number

      uncheck 'Only show complete orders'
      page.find('a.icon-search').click

      expect(page).to have_content complete_order.number
      expect(page).to have_content incomplete_order.number
      expect(page).to have_no_content empty_order.number
    end
  end

  context "save the filter params" do
    let!(:shipping_method) { create(:shipping_method, name: "UPS Ground") }
    let!(:user) { create(:user, email: 'an@email.com') }
    let!(:order) do
      create(
        :order,
        distributor: distributor,
        order_cycle: order_cycle,
        user: user,
        number: "R123456",
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago
      )
    end
    before :each do
      login_as_admin_and_visit spree.admin_orders_path

      # Specify each filters
      uncheck 'Only show complete orders'
      fill_in "Invoice number", with: "R123456"
      select2_select order_cycle.name, from: 'q_order_cycle_id_in'
      select2_select distributor.name, from: 'q_distributor_id_in'
      select2_select shipping_method.name, from: 'q_shipping_method_id'
      select2_select "complete", from: 'q_state_eq'
      fill_in "Email", with: user.email
      fill_in "First name begins with", with: "J"
      fill_in "Last name begins with", with: "D"
      find("input.datepicker").click
      select_dates_from_daterangepicker(Time.zone.at(1.week.ago), Time.zone.now.tomorrow)

      page.find('a.icon-search').click
    end

    it "when reloading the page" do
      page.driver.refresh

      # Check every filters to be equal
      expect(find_field("Only show complete orders")).not_to be_checked
      expect(find_field("Invoice number").value).to eq "R123456"
      expect(find("#s2id_q_shipping_method_id").text).to eq shipping_method.name
      expect(find("#s2id_q_state_eq").text).to eq "complete"
      expect(find("#s2id_q_distributor_id_in").text).to eq distributor.name
      expect(find("#s2id_q_order_cycle_id_in").text).to eq order_cycle.name
      expect(find_field("Email").value).to eq user.email
      expect(find_field("First name begins with").value).to eq "J"
      expect(find_field("Last name begins with").value).to eq "D"
      expect(find("input.datepicker").value).to eq "#{1.week.ago.strftime('%Y-%m-%d')} to #{Time.zone.now.tomorrow.strftime('%Y-%m-%d')}"
    end

    it "and clear filters" do
      find("a#clear_filters_button").click
      expect(find_field("Only show complete orders")).to be_checked
      expect(find_field("Invoice number").value).to eq ""
      expect(find("#s2id_q_shipping_method_id").text).to be_empty
      expect(find("#s2id_q_state_eq").text).to be_empty
      expect(find("#s2id_q_distributor_id_in").text).to be_empty
      expect(find("#s2id_q_order_cycle_id_in").text).to be_empty
      expect(find_field("Email").value).to be_empty
      expect(find_field("First name begins with").value).to be_empty
      expect(find_field("Last name begins with").value).to be_empty
      expect(find("input.datepicker").value).to be_empty
    end
  end
end
