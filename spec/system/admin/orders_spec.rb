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
  let(:distributor) {
    create(:distributor_enterprise, owner:, with_payment_and_shipping: true,
                                    charges_sales_tax: true)
  }
  let(:distributor2) { create(:distributor_enterprise_with_tax, owner:) }
  let(:distributor3) {
    create(:distributor_enterprise, owner:, with_payment_and_shipping: true,
                                    charges_sales_tax: true)
  }
  let(:distributor4) {
    create(:distributor_enterprise, owner:, with_payment_and_shipping: true,
                                    charges_sales_tax: true)
  }
  let(:distributor5) { create(:distributor_enterprise, owner: owner2, charges_sales_tax: true) }
  let!(:shipping_method) {
    create(:shipping_method_with, :pickup, name: "pick_up",
                                           distributors: [distributor, distributor2, distributor3])
  }
  let!(:shipping_method2) {
    create(:shipping_method_with, :pickup, name: "delivery",
                                           distributors: [distributor4, distributor5])
  }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor, distributor2,
                                                            distributor3, distributor4],
                                variants: [product.variants.first])
  end

  context "with a complete order" do
    let(:order) do
      create(:order_with_totals_and_distribution, user: customer, distributor:,
                                                  order_cycle:,
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
      create(:simple_order_cycle, name: 'Five', coordinator: distributor5,
                                  distributors: [distributor5], variants: [product.variants.first])
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

    describe "filters" do
      before do
        login_as_admin
        visit spree.admin_orders_path
      end

      it "order cycles appear in descending order by close date on orders page" do
        tomselect_open('q_order_cycle_id_in').click

        expect(find('#q_order_cycle_id_in',
                    visible: :all)[:innerHTML]).to have_content(/.*Four.*Three.*Two.*Five/m)
      end

      it "filter by multiple order cycles" do
        tomselect_multiselect 'Two', from: 'q[order_cycle_id_in][]'
        tomselect_multiselect 'Three', from: 'q[order_cycle_id_in][]'

        page.find('.filter-actions .button[type=submit]').click

        # Order 2 and 3 should show, but not 4
        expect(page).to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).not_to have_content order4.number
      end

      it "filter by distributors" do
        tomselect_multiselect distributor2.name.to_s, from: 'q[distributor_id_in][]'
        tomselect_multiselect distributor4.name.to_s, from: 'q[distributor_id_in][]'

        page.find('.filter-actions .button[type=submit]').click

        # Order 2 and 4 should show, but not 3
        expect(page).to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).to have_content order4.number
      end

      it "filter by complete date" do
        find("input.datepicker").click
        select_dates_from_daterangepicker(order3.completed_at.yesterday,
                                          order4.completed_at.tomorrow)

        page.find('.filter-actions .button[type=submit]').click

        # Order 3 and 4 should show, but not 2
        expect(page).not_to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).to have_content order4.number
      end

      it "filter by email" do
        fill_in "Email", with: customer3.email

        page.find('.filter-actions .button[type=submit]').click

        # Order 3 should show, but not 2 and 4
        expect(page).not_to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).not_to have_content order4.number
      end

      it "filter by customer first and last names" do
        # NOTE: this field refers to the name given in billing addresses and not to customer name
        # filtering by first name
        fill_in "First name begins with", with: billing_address2.firstname
        page.find('.filter-actions .button[type=submit]').click
        # Order 2 should show, but not 3 and 4
        expect(page).to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).not_to have_content order4.number

        find("#clear_filters_button").click
        # filtering by last name

        fill_in "Last name begins with", with: billing_address4.lastname
        page.find('.filter-actions .button[type=submit]').click
        # Order 4 should show, but not 2 and 3
        expect(page).not_to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).to have_content order4.number

        find("#clear_filters_button").click
        # filtering by first and last name together

        fill_in "First name begins with", with: billing_address3.firstname
        fill_in "Last name begins with", with: billing_address3.lastname
        page.find('.filter-actions .button[type=submit]').click
        # Order 3 should show, but not 2 and 4
        expect(page).not_to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).not_to have_content order4.number
      end

      it "filter by shipping methods" do
        order2.select_shipping_method(shipping_method.id)
        order4.select_shipping_method(shipping_method2.id)

        tomselect_search_and_select "Pick-up at the farm", from: 'shipping_method_id'
        page.find('.filter-actions .button[type=submit]').click
        # Order 2 should show, but not 3 and 5
        expect(page).to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).not_to have_content order4.number

        find("#clear_filters_button").click

        tomselect_search_and_select "Signed, sealed, delivered", from: 'shipping_method_id'
        page.find('.filter-actions .button[type=submit]').click
        # Order 4 should show, but not 2 and 3
        expect(page).not_to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).to have_content order4.number
      end

      it "filter by invoice number" do
        fill_in "Order number:", with: order2.number

        page.find('.filter-actions .button[type=submit]').click

        # Order 2 should show, but not 3 and 4
        expect(page).to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).not_to have_content order4.number
      end

      it "filter by order state" do
        order.update(state: "payment")

        uncheck 'Only show complete orders'
        page.find('.filter-actions .button[type=submit]').click

        expect(page).to have_content order.number
        expect(page).to have_content order2.number
        expect(page).to have_content order3.number
        expect(page).to have_content order4.number
        expect(page).to have_content order5.number

        tomselect_search_and_select "payment", from: 'q[state_eq]'

        page.find('.filter-actions .button[type=submit]').click

        # Order 2 should show, but not 3 and 4
        expect(page).to have_content order.number
        expect(page).not_to have_content order2.number
        expect(page).not_to have_content order3.number
        expect(page).not_to have_content order4.number
        expect(page).not_to have_content order5.number
      end
    end

    context "cart orders" do
      let!(:order_empty) {
        create(:order_with_line_items, user: customer2, distributor: distributor2,
                                       line_items_count: 0)
      }

      let!(:order_not_empty) {
        create(:order_with_line_items, user: customer2, distributor: distributor2,
                                       line_items_count: 1)
      }

      let!(:order_not_empty_no_address) {
        create(:order_with_line_items, line_items_count: 1, user: customer2,
                                       distributor: distributor2, bill_address_id: nil,
                                       ship_address_id: nil)
      }

      before do
        login_as_admin
        visit spree.admin_orders_path
        uncheck 'Only show complete orders'
        tomselect_search_and_select "cart", from: 'q[state_eq]'
        page.find('.filter-actions .button[type=submit]').click
      end

      it "displays non-empty cart orders" do
        # empty cart order does not appear in the results
        expect(page).not_to have_content order_empty.number

        # non-empty cart order, with bill- and ship-address appear in the results
        expect(page).to have_content order_not_empty.number

        # non-empty cart order, with no with bill- and ship-address appear in the results
        expect(page).to have_content order_not_empty_no_address.number

        # And the same orders are displayed when sorting by name:
        find("th a", text: "NAME").click

        expect(page).not_to have_content order_empty.number
        expect(page).to have_content order_not_empty.number
        expect(page).to have_content order_not_empty_no_address.number
      end
    end

    describe "ordering" do
      context "orders with different completion dates" do
        before do
          order2.update!(completed_at: 2.weeks.ago)
          order3.update!(completed_at: 3.weeks.ago)
          order4.update!(completed_at: 4.weeks.ago)
          order5.update!(completed_at: 5.weeks.ago)
          login_as_admin
          visit spree.admin_orders_path
        end
        it "orders by completion date" do
          find("a", text: 'COMPLETED AT').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'COMPLETED AT').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end

      context "orders with different order numbers" do
        before do
          order2.update!(number: "R555555555")
          order3.update!(number: "R444444444")
          order4.update!(number: "R333333333")
          order5.update!(number: "R222222222")
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by order number" do
          find("a", text: 'NUMBER').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'NUMBER').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end

      context "orders with different states" do
        before do
          order2.update!(state: "payment")
          order3.update!(state: "complete")
          order4.update!(state: "cart")
          order5.cancel
          login_as_admin
          visit spree.admin_orders_path
          uncheck 'Only show complete orders'
          page.find('.filter-actions .button[type=submit]').click
        end

        it "orders by order state" do
          find("a", text: 'STATE').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'STATE').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end

      context "orders with different payment states" do
        before do
          Spree::Payment.where(order_id: order2.id).first.update!(amount: 50.0)
          Spree::Payment.where(order_id: order3.id).first.update!(amount: 100.0)
          Spree::Payment.where(order_id: order4.id).first.update!(amount: 10.0)
          login_as_admin
          visit spree.admin_orders_path
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
          login_as_admin
          visit spree.admin_orders_path
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
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by customer email" do
          find("a", text: 'EMAIL').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'EMAIL').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end

      context "orders with different billing addresses" do
        before do
          billing_address2.update!(firstname: "Mad", lastname: "Hatter")
          billing_address3.update!(firstname: "Alice", lastname: "Smith")
          billing_address4.update!(firstname: "Cheshire", lastname: "Cat")
          billing_address5.update!(firstname: "Bob", lastname: "Smith")
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by last name then first name" do
          find("a", text: 'NAME').click # sets ascending ordering
          expect(page).to have_content(
            /#{order4.number}.*#{order2.number}.*#{order3.number}.*#{order5.number}/m
          )
          find("a", text: 'NAME').click # sets descending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order3.number}.*#{order2.number}.*#{order4.number}/m
          )
        end
      end

      context "displaying order special instructions" do
        before do
          order3.update(special_instructions: "Leave it next to the porch. Thanks!")
          login_as_admin
          visit spree.admin_orders_path
        end

        it "displays a note with order instructions" do
          within "tr#order_#{order3.id}" do
            expect(page).to have_content "Note"
            find(".icon-warning-sign").hover
            expect(page).to have_content(/#{order3.special_instructions}/i)
          end
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
          login_as_admin
          visit spree.admin_orders_path
        end

        it "orders by order total" do
          find("a", text: 'TOTAL').click # sets ascending ordering
          expect(page).to have_content(
            /#{order5.number}.*#{order4.number}.*#{order3.number}.*#{order2.number}/m
          )
          find("a", text: 'TOTAL').click # sets descending ordering
          expect(page).to have_content(
            /#{order2.number}.*#{order3.number}.*#{order4.number}.*#{order5.number}/m
          )
        end
      end
    end

    context "select/unselect all orders" do
      before do
        login_as_admin
        visit spree.admin_orders_path
      end

      it "by clicking on the checkbox in the table header" do
        # select all orders
        page.find("#listing_orders thead th:first-child input[type=checkbox]").click
        expect(page.find(
                 "#listing_orders tbody tr td:first-child input[type=checkbox]"
               )).to be_checked
        # enables print invoices button
        page.find("span.icon-reorder", text: "ACTIONS").click
        expect(page).to have_content "Print Invoices"
        # unselect all orders
        page.find("#listing_orders thead th:first-child input[type=checkbox]").trigger("click")
        expect(page.find(
                 "#listing_orders tbody tr td:first-child input[type=checkbox]"
               )).not_to be_checked
        # disables print invoices button not clickable
        expect { find("span.icon-reorder", text: "ACTIONS").click }
          .to raise_error(Capybara::Cuprite::MouseEventFailed)
        expect(page).not_to have_content "Print Invoices"
      end
    end

    context "bulk actions" do
      context "as a super admin" do
        before do
          login_as_admin
          visit spree.admin_orders_path
        end

        context "can bulk send invoices per email" do
          before do
            Spree::Config[:enable_invoices?] = true
            Spree::Config[:enterprise_number_required_on_invoices?] = false
          end

          context "with multiple orders with differents states" do
            before do
              order2.update(state: "complete")
              order3.update(state: "resumed")
              order4.update(state: "canceled")
              order5.update(state: "payment")
            end

            it "can bulk send invoices per email, but only for the 'complete' or 'resumed' ones" do
              within "#listing_orders" do
                page.find("input[name='bulk_ids[]'][value='#{order2.id}']").click
                page.find("input[name='bulk_ids[]'][value='#{order3.id}']").click
                page.find("input[name='bulk_ids[]'][value='#{order4.id}']").click
                page.find("input[name='bulk_ids[]'][value='#{order5.id}']").click
              end

              page.find("span.icon-reorder", text: "ACTIONS").click
              within ".ofn-drop-down .menu" do
                page.find("span", text: "Send Invoices").click
              end

              expect(page).to have_content "This will email customer invoices " \
                                           "for all selected complete orders."
              expect(page).to have_content "Are you sure you want to proceed?"

              within ".reveal-modal" do
                expect {
                  find_button("Confirm").click
                }.to enqueue_job(ActionMailer::MailDeliveryJob).exactly(:twice)
              end

              expect(page).to have_content "Invoice emails sent for 2 orders."
            end
          end

          it "can bulk send confirmation email from 2 orders" do
            page.find("#listing_orders tbody tr:nth-child(1) input[name='bulk_ids[]']").click
            page.find("#listing_orders tbody tr:nth-child(2) input[name='bulk_ids[]']").click

            page.find("span.icon-reorder", text: "ACTIONS").click
            within ".ofn-drop-down .menu" do
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
        end

        context "can bulk print invoices" do
          def extract_pdf_content
            # Extract last part of invoice URL
            link = page.find(class: "button", text: "VIEW FILE")
            filename = link[:href].match %r{/invoices/.*}

            # Load invoice temp file directly instead of downloading
            reader = PDF::Reader.new("tmp/#{filename}.pdf")
            reader.pages.map(&:text)
          end

          let(:order4_selector){ "#order_#{order4.id} input[name='bulk_ids[]']" }
          let(:order5_selector){ "#order_#{order5.id} input[name='bulk_ids[]']" }

          shared_examples "can bulk print invoices from 2 orders" do
            it "bulk prints invoices in pdf format" do
              page.find(order4_selector).click
              page.find(order5_selector).click

              page.find("span.icon-reorder", text: "ACTIONS").click
              within ".ofn-drop-down .menu" do
                expect {
                  page.find("span", text: "Print Invoices").click # Prints invoices in bulk
                }.to enqueue_job(BulkInvoiceJob).exactly(:once)
              end

              expect(page).to have_content "Compiling Invoices"
              expect(page).to have_content "Please wait until the PDF is ready " \
                                           "before closing this modal."

              # we don't run Sidekiq in test environment, so we need to manually run enqueued jobs
              # to generate PDF files, and change the modal accordingly
              perform_enqueued_jobs(only: BulkInvoiceJob)

              expect(page).to have_content "Bulk Invoice created"

              within ".modal-content" do
                expect(page).to have_link(class: "button", text: "VIEW FILE", href: /invoices/)

                invoice_content = extract_pdf_content

                expect(invoice_content).to have_content("TAX INVOICE", count: 2)
                expect(invoice_content).to have_content(order4.number.to_s)
                expect(invoice_content).to have_content(order5.number.to_s)
                expect(invoice_content).to have_content(distributor4.name.to_s)
                expect(invoice_content).to have_content(distributor5.name.to_s)
                expect(invoice_content).to have_content(order_cycle4.name.to_s)
                expect(invoice_content).to have_content(order_cycle5.name.to_s)
              end
            end
          end

          shared_examples "should ignore the non invoiceable order" do
            it "bulk prints invoices in pdf format" do
              page.find(order4_selector).click
              page.find(order5_selector).click

              page.find("span.icon-reorder", text: "ACTIONS").click
              within ".ofn-drop-down .menu" do
                expect {
                  page.find("span", text: "Print Invoices").click # Prints invoices in bulk
                }.to enqueue_job(BulkInvoiceJob).exactly(:once)
              end

              expect(page).to have_content "Compiling Invoices"
              expect(page).to have_content "Please wait until the PDF is ready " \
                                           "before closing this modal."

              perform_enqueued_jobs(only: BulkInvoiceJob)

              expect(page).to have_content "Bulk Invoice created"

              within ".modal-content" do
                expect(page).to have_link(class: "button", text: "VIEW FILE",
                                          href: /invoices/)

                invoice_content = extract_pdf_content

                expect(invoice_content).to have_content("TAX INVOICE", count: 1)
                expect(invoice_content).not_to have_content(order4.number.to_s)
                expect(invoice_content).to have_content(order5.number.to_s)
                expect(invoice_content).not_to have_content(distributor4.name.to_s)
                expect(invoice_content).to have_content(distributor5.name.to_s)
                expect(invoice_content).not_to have_content(order_cycle4.name.to_s)
                expect(invoice_content).to have_content(order_cycle5.name.to_s)
              end
            end
          end

          shared_examples "prints invoices accordering to column ordering" do
            it "bulk prints invoices in pdf format" do
              page.find("span.icon-reorder", text: "ACTIONS").click
              within ".ofn-drop-down .menu" do
                expect {
                  page.find("span", text: "Print Invoices").click # Prints invoices in bulk
                }.to enqueue_job(BulkInvoiceJob).exactly(:once)
              end

              expect(page).to have_content "Compiling Invoices"
              expect(page).to have_content "Please wait until the PDF is ready " \
                                           "before closing this modal."

              perform_enqueued_jobs(only: BulkInvoiceJob)

              expect(page).to have_content "Bulk Invoice created"

              within ".modal-content" do
                expect(page).to have_link(class: "button", text: "VIEW FILE",
                                          href: /invoices/)

                invoice_content = extract_pdf_content

                expect(
                  invoice_content
                ).to match(/#{surnames[0]}.*#{surnames[1]}.*#{surnames[2]}.*#{surnames[3]}/m)
              end
            end
          end

          context "ABN is not required" do
            before do
              allow(Spree::Config).to receive(:enterprise_number_required_on_invoices?)
                .and_return false
            end

            it_behaves_like "can bulk print invoices from 2 orders"

            context "with legal invoices feature", feature: :invoices do
              it_behaves_like "can bulk print invoices from 2 orders"
            end
            context "ordering by customer name" do
              context "ascending" do
                let!(:surnames) {
                  [order2.name.gsub(/.* /, ""), order3.name.gsub(/.* /, ""),
                   order4.name.gsub(/.* /, ""), order5.name.gsub(/.* /, "")].sort
                }
                before do
                  pending("#12340")
                  page.find('a', text: "NAME").click # orders alphabetically (asc)
                  sleep(0.5) # waits for column sorting
                  page.find('#selectAll').click
                end
                it_behaves_like "prints invoices accordering to column ordering"
              end
              context "descending" do
                let!(:surnames) {
                  [order2.name.gsub(/.* /, ""), order3.name.gsub(/.* /, ""),
                   order4.name.gsub(/.* /, ""), order5.name.gsub(/.* /, "")].sort.reverse
                }
                before do
                  pending("#12340")
                  page.find('a', text: "NAME").click # orders alphabetically (asc)
                  sleep(0.5) # waits for column sorting
                  page.find('a', text: "NAME").click # orders alphabetically (desc)
                  sleep(0.5) # waits for column sorting
                  page.find('#selectAll').click
                end
                it_behaves_like "prints invoices accordering to column ordering"
              end
            end
            context "one of the two orders is not invoiceable" do
              before do
                order4.cancel!
              end

              it_behaves_like "should ignore the non invoiceable order"
              context "with legal invoices feature", feature: :invoices do
                it_behaves_like "should ignore the non invoiceable order"
              end
            end
          end
          context "ABN is required" do
            before do
              allow(Spree::Config).to receive(:enterprise_number_required_on_invoices?)
                .and_return true
            end
            context "All the distributors setup the ABN" do
              before do
                order4.distributor.update(abn: "123456789")
                order5.distributor.update(abn: "987654321")
              end
              context "all the orders are invoiceable (completed/resumed)" do
                it_behaves_like "can bulk print invoices from 2 orders"
                context "with legal invoices feature", feature: :invoices do
                  it_behaves_like "can bulk print invoices from 2 orders"
                end
              end

              context "one of the two orders is not invoiceable" do
                before do
                  order4.cancel!
                end

                it_behaves_like "should ignore the non invoiceable order"
                context "with legal invoices feature", feature: :invoices do
                  it_behaves_like "should ignore the non invoiceable order"
                end
              end
            end
            context "the distributor of one of the order didn't set the ABN" do
              before do
                order4.distributor.update(abn: "123456789")
                order5.distributor.update(abn: nil)
              end

              shared_examples "should not print the invoice" do
                it "should render a warning message" do
                  page.find(order4_selector).click
                  page.find(order5_selector).click

                  page.find("span.icon-reorder", text: "ACTIONS").click
                  within ".ofn-drop-down .menu" do
                    expect {
                      page.find("span", text: "Print Invoices").click # Prints invoices in bulk
                    }.not_to enqueue_job(BulkInvoiceJob)
                  end

                  expect(page).not_to have_content "Compiling Invoices"
                  expect(page).not_to have_content "Please wait until the PDF is ready " \
                                                   "before closing this modal."

                  expect(page).to have_content "#{
                    order5.distributor.name
                  } must have a valid ABN before invoices can be used."
                end
              end
              it_behaves_like "should not print the invoice"
              context "with legal invoices feature", feature: :invoices do
                it_behaves_like "should not print the invoice"
              end
            end
          end
        end
        it "can bulk cancel 2 orders" do
          page.find("#listing_orders tbody tr:nth-child(1) input[name='bulk_ids[]']").click
          page.find("#listing_orders tbody tr:nth-child(2) input[name='bulk_ids[]']").click

          page.find("span.icon-reorder", text: "ACTIONS").click
          within ".ofn-drop-down .menu" do
            page.find("span", text: "Cancel Orders").click
          end

          expect(page).to have_content "Are you sure you want to proceed?"
          expect(page).to have_content "This will cancel the current order."

          within ".reveal-modal" do
            uncheck "Send a cancellation email to the customer"
            expect {
              find_button("Cancel").click # Cancels the cancel action
            }.not_to enqueue_job(ActionMailer::MailDeliveryJob).exactly(:twice)
          end

          page.find("span.icon-reorder", text: "ACTIONS").click
          within ".ofn-drop-down .menu" do
            page.find("span", text: "Cancel Orders").click
          end

          within ".reveal-modal" do
            expect {
              find_button("Confirm").click # Confirms the cancel action
            }.not_to enqueue_job(ActionMailer::MailDeliveryJob).exactly(:twice)
          end

          expect(page).to have_content("CANCELLED", count: 2)
        end
      end

      context "for a hub manager" do
        before do
          login_as owner2
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
          page.find("#listing_orders tbody tr:nth-child(1) input[name='bulk_ids[]']").click
          # Find the clicked order
          order = Spree::Order.find_by(
            id: page.find("#listing_orders tbody tr:nth-child(1) input[name='bulk_ids[]']").value
          )
          # Revoke permission for the current user on that specific order by changing its owners
          order.update_attribute(:distributor, distributor)
          order.update_attribute(:order_cycle, order_cycle)

          page.find("span.icon-reorder", text: "ACTIONS").click
          within ".ofn-drop-down .menu" do
            page.find("span", text: "Resend Confirmation").click
          end

          expect(page).to have_content "Are you sure you want to proceed?"

          within ".reveal-modal" do
            expect {
              find_button("Confirm").click
            }.not_to enqueue_job(ActionMailer::MailDeliveryJob)
          end
        end
      end
    end

    context "pagination" do
      before do
        login_as_admin
        visit spree.admin_orders_path
      end

      it "displays pagination options" do
        # displaying 4 orders (one order per table row)
        within('tbody') do
          expect(page).to have_css('tr', count: 4)
        end
        # pagination options also refer 4 order
        expect(page).to have_content "4 Results found. Viewing 1 to 4."
        page.find(".per-page-dropdown .ts-control .item").click # toggling the pagination dropdown
        expect(page).to have_content "15 per page"
        expect(page).to have_content "50 per page"
        expect(page).to have_content "100 per page"
      end
    end

    context "with a capturable order" do
      before do
        order.finalize! # ensure order has a payment to capture
        order.payments << create(:check_payment, order:, amount: order.total)
      end

      it "capture payment" do
        login_as_admin
        visit spree.admin_orders_path
        expect(page).to have_current_path spree.admin_orders_path

        # click the 'capture' link for the order
        page.find("button.icon-capture").click

        expect(page).to have_css "i.success"
        expect(page).to have_css "button.icon-road"

        # check the order was captured
        expect(order.reload.payment_state).to eq "paid"

        # we should still be on the same page
        expect(page).to have_current_path spree.admin_orders_path
      end

      it "ship order from the orders index page and send email" do
        order.payments.first.capture!
        login_as_admin
        visit spree.admin_orders_path

        page.find("button.icon-road").click

        within ".reveal-modal" do
          expect {
            find_button("Confirm").click
          }.to enqueue_job(ActionMailer::MailDeliveryJob).exactly(:once)
        end
        expect(page).to have_css "i.success"
        expect(order.reload.shipments.any?(&:shipped?)).to be true
        expect(order.shipment_state).to eq("shipped")
      end

      it "ship order from the orders index page and do not send email" do
        order.payments.first.capture!
        login_as_admin
        visit spree.admin_orders_path

        page.find("button.icon-road").click

        within ".reveal-modal" do
          uncheck 'Send a shipment/pick up notification email to the customer.'
          expect {
            find_button("Confirm").click
          }.not_to enqueue_job(ActionMailer::MailDeliveryJob)
        end
        expect(page).to have_css "i.success"
        expect(order.reload.shipments.any?(&:shipped?)).to be true
        expect(order.shipment_state).to eq("shipped")
      end

      context "mouse-hovering" do
        before do
          login_as_admin
          visit spree.admin_orders_path
        end

        it "displays Ship and Capture tooltips" do
          within "tr#order_#{order2.id}" do
            # checks shipment state
            expect(page).to have_content "READY"

            # mouse-hovers and finds tooltip
            find(".icon-road").hover
            expect(page).to have_content "Ship"
          end

          within "tr#order_#{order.id}" do
            # checks shipment state
            expect(page).to have_content "PENDING"

            # mouse-hovers and finds tooltip
            find(".icon-capture").hover
            expect(page).to have_content "Capture"
          end
        end

        it "displays Ship and Edit tooltips, after capturing a payment" do
          within "tr#order_#{order.id}" do
            # checks the order has an uncaptured payment
            find(".icon-capture").hover
            expect(page).to have_content "Capture"

            # captures the payment
            find(".icon-capture").click
            expect(page).not_to have_content "Capture"

            # checks shipment state
            expect(page).to have_content "READY"

            # move away from the Ship button so we can trigger the mouseenter event by moving back.
            # We are already on the "Ship" button when it gets rendered because of
            # the previous click
            find(".icon-edit").hover
            # mouse-hovers and finds Ship tooltip
            find(".icon-road").hover
            expect(page).to have_content "Ship"

            # mouse-hovers and finds Edit tooltip
            find(".icon-edit").hover
            expect(page).to have_content "Edit"
          end
        end

        it "displays Edit tooltip" do
          within "tr#order_#{order.id}" do
            # checks shipment state
            expect(page).to have_content "PENDING"

            # mouse-hovers and finds tooltip
            find(".icon-edit").hover
            expect(page).to have_content "Edit"
          end
        end
      end
    end
  end

  context "with incomplete order" do
    it "can edit order" do
      incomplete_order = create(:order_with_line_items, distributor:,
                                                        order_cycle:,
                                                        line_items_count: 1)

      login_as_admin
      visit spree.admin_orders_path
      uncheck 'Only show complete orders'
      page.find('button[type=submit]').click

      find(".icon-edit").click

      expect(page).to have_current_path spree.edit_admin_order_path(incomplete_order)
    end
  end

  context "test the 'Only show the complete orders' checkbox" do
    it "display or not incomplete order" do
      incomplete_order = create(:order_with_line_items, distributor:,
                                                        order_cycle:,
                                                        line_items_count: 1)
      complete_order = create(
        :order_with_line_items,
        distributor:,
        order_cycle:,
        user: customer,
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago,
        line_items_count: 1
      )

      empty_complete_order = create(
        :order_with_line_items,
        distributor:,
        order_cycle:,
        user: customer,
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago,
        line_items_count: 0
      )

      empty_order = create(:order, distributor:, order_cycle:)

      login_as_admin
      visit spree.admin_orders_path
      expect(page).to have_content complete_order.number
      expect(page).to have_content empty_complete_order.number
      expect(page).not_to have_content incomplete_order.number
      expect(page).not_to have_content empty_order.number

      uncheck 'Only show complete orders'
      page.find('button[type=submit]').click

      expect(page).to have_content complete_order.number
      expect(page).to have_content incomplete_order.number
      expect(page).not_to have_content empty_order.number
    end
  end

  context "save the filter params" do
    let!(:shipping_method) { create(:shipping_method, name: "UPS Ground") }
    let!(:user) { create(:user, email: 'an@email.com') }
    let!(:order) do
      create(
        :order,
        distributor:,
        order_cycle:,
        user:,
        number: "R123456",
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago
      )
    end
    before :each do
      login_as_admin
      visit spree.admin_orders_path

      # Specify each filters
      uncheck 'Only show complete orders'
      fill_in "Order number", with: "R123456"
      tomselect_multiselect order_cycle.name, from: 'q[order_cycle_id_in][]'
      tomselect_multiselect distributor.name, from: 'q[distributor_id_in][]'
      tomselect_select shipping_method.name, from: 'shipping_method_id'
      tomselect_select "complete", from: 'q[state_eq]'
      fill_in "Email", with: user.email
      fill_in "First name begins with", with: "J"
      fill_in "Last name begins with", with: "D"
      find("input.datepicker").click
      select_dates_from_daterangepicker(Time.zone.at(1.week.ago), Time.zone.now.tomorrow)

      page.find('.button[type=submit]').click
    end

    it "when reloading the page" do
      page.driver.refresh

      # Check every filters to be equal
      expect(find_field("Only show complete orders")).not_to be_checked
      expect(find_field("Order number").value).to eq "R123456"
      expect(find("#shipping_method_id-ts-control .item").text).to eq shipping_method.name
      expect(find("#q_state_eq-ts-control .item").text).to eq "complete"
      expect(find("#q_distributor_id_in").value).to eq [distributor.id.to_s]
      expect(find("#q_order_cycle_id_in").value).to eq [order_cycle.id.to_s]
      expect(find_field("Email").value).to eq user.email
      expect(find_field("First name begins with").value).to eq "J"
      expect(find_field("Last name begins with").value).to eq "D"
      expect(find("input.datepicker").value).to eq(
        "#{1.week.ago.strftime('%Y-%m-%d')} to #{Time.zone.now.tomorrow.strftime('%Y-%m-%d')}"
      )
    end

    it "and clear filters" do
      find("#clear_filters_button").click
      expect(find_field("Only show complete orders")).to be_checked
      expect(find_field("Order number").value).to eq ""
      expect(find("#shipping_method_id").value).to be_empty
      expect(find("#q_state_eq").value).to be_empty
      expect(find("#q_distributor_id_in").value).to be_empty
      expect(find("#q_order_cycle_id_in").value).to be_empty
      expect(find_field("Email").value).to be_empty
      expect(find_field("First name begins with").value).to be_empty
      expect(find_field("Last name begins with").value).to be_empty
      expect(find("input.datepicker").value).to be_empty
    end
  end
end
