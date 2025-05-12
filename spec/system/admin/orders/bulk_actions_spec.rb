# frozen_string_literal: true

require "system_helper"

RSpec.describe '
    As an administrator
    I want to perform bulk order actions
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
    create(:shipping_method_with, :delivery, name: "delivery",
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

        shared_examples "can bulk send confirmation email from 2 orders" do
          it "can bulk send invoices per email, but only for the 'complete' or 'resumed' ones" do
            within "#listing_orders" do
              page.find("input[name='bulk_ids[]'][value='#{order2.id}']").click
              page.find("input[name='bulk_ids[]'][value='#{order3.id}']").click
              page.find("input[name='bulk_ids[]'][value='#{order4.id}']").click
              page.find("input[name='bulk_ids[]'][value='#{order5.id}']").click
            end

            page.find("span.icon-reorder", text: "Actions").click

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

        context "with multiple orders with differents states" do
          before do
            order2.update(state: "canceled")
            order3.update(state: "payment")
            order4.update(state: "complete")
            order5.update(state: "resumed")
          end

          it_behaves_like "can bulk send confirmation email from 2 orders"

          describe "ABN" do
            context "ABN is not required" do
              before do
                allow(Spree::Config).to receive(:enterprise_number_required_on_invoices?)
                  .and_return false
              end
              it_behaves_like "can bulk send confirmation email from 2 orders"
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
                  it_behaves_like "can bulk send confirmation email from 2 orders"
                end
              end
              context "the distributor of one of the order didn't set the ABN" do
                context "ABN is nil" do
                  before do
                    order4.distributor.update(abn: "123456789")
                    order5.distributor.update(abn: nil)
                  end

                  context "with legal invoices feature disabled" do
                    before { pending("Emails are not sent in this case") }
                    it_behaves_like "can bulk send confirmation email from 2 orders"
                  end
                end

                context "ABN is an empty string" do
                  before do
                    order4.distributor.update(abn: "123456789")
                    order5.distributor.update(abn: "")
                  end

                  context "with legal invoices feature disabled" do
                    before { pending("Emails are not sent in this case") }
                    it_behaves_like "can bulk send confirmation email from 2 orders"
                  end
                end
              end
            end
          end
        end
      end

      context "can bulk print invoices" do
        let(:order4_selector){ "#order_#{order4.id} input[name='bulk_ids[]']" }
        let(:order5_selector){ "#order_#{order5.id} input[name='bulk_ids[]']" }

        shared_examples "can bulk print invoices from 2 orders" do
          it "bulk prints invoices in pdf format" do
            page.find(order4_selector).click
            page.find(order5_selector).click

            page.find("span.icon-reorder", text: "Actions").click
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
              expect(page).to have_link(class: "button", text: "View File", href: /invoices/)

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

            page.find("span.icon-reorder", text: "Actions").click
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
              expect(page).to have_link(class: "button", text: "View File",
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

        context "ABN is not required" do
          before do
            allow(Spree::Config).to receive(:enterprise_number_required_on_invoices?)
              .and_return false
          end

          it_behaves_like "can bulk print invoices from 2 orders"

          context "with legal invoices feature", feature: :invoices do
            it_behaves_like "can bulk print invoices from 2 orders"
          end

          context "when cable_ready fails" do
            # The backup polling is slower. Let's wait for it.
            around do |example|
              polling_interval = 5 # seconds
              wait_time = Capybara.default_max_wait_time + polling_interval

              using_wait_time(wait_time) do
                example.run
              end
            end

            # Don't send anything via web sockets.
            before do
              expect_any_instance_of(BulkInvoiceJob)
                .to receive(:broadcast)
                .and_return(nil) # do nothing
            end

            it_behaves_like "can bulk print invoices from 2 orders"
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

          context "ordering by customer name" do
            context "ascending" do
              let!(:surnames) {
                [order2.name.gsub(/.* /, ""), order3.name.gsub(/.* /, ""),
                 order4.name.gsub(/.* /, ""), order5.name.gsub(/.* /, "")].sort
              }
              it "orders by customer name ascending" do
                page.find('a', text: "Name").click # orders alphabetically (asc)
                sleep(0.5) # waits for column sorting

                page.find("#selectAll").click

                print_all_invoices

                invoice_content = extract_pdf_content

                expect(
                  invoice_content.join
                ).to match(/#{surnames[0]}.*#{surnames[1]}.*#{surnames[2]}.*#{surnames[3]}/m)
              end
            end
            context "descending" do
              let!(:surnames) {
                [order2.name.gsub(/.* /, ""), order3.name.gsub(/.* /, ""),
                 order4.name.gsub(/.* /, ""), order5.name.gsub(/.* /, "")].sort.reverse
              }
              it "order by customer name descending" do
                page.find('a', text: "Name").click # orders alphabetically (asc)
                sleep(0.5) # waits for column sorting
                page.find('a', text: "Name").click # orders alphabetically (desc)
                sleep(0.5) # waits for column sorting

                page.find("#selectAll").click

                print_all_invoices

                invoice_content = extract_pdf_content

                expect(
                  invoice_content.join
                ).to match(/#{surnames[0]}.*#{surnames[1]}.*#{surnames[2]}.*#{surnames[3]}/m)
              end
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
            shared_examples "should not print the invoice" do
              it "should render a warning message" do
                page.find(order4_selector).click
                page.find(order5_selector).click

                page.find("span.icon-reorder", text: "Actions").click
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

            context "ABN is nil" do
              before do
                order4.distributor.update(abn: "123456789")
                order5.distributor.update(abn: nil)
              end

              context "with legal invoices feature disabled" do
                it_behaves_like "should not print the invoice"
              end

              context "with legal invoices feature", feature: :invoices do
                it_behaves_like "should not print the invoice"
              end
            end

            context "ABN is an empty string" do
              before do
                order4.distributor.update(abn: "123456789")
                order5.distributor.update(abn: "")
              end

              context "with legal invoices feature disabled" do
                it_behaves_like "can bulk print invoices from 2 orders"
              end

              context "with legal invoices feature", feature: :invoices do
                it_behaves_like "should not print the invoice"
              end
            end
          end
        end
      end

      it "can bulk cancel 2 orders" do
        page.find("#listing_orders tbody tr:nth-child(1) input[name='bulk_ids[]']").click
        page.find("#listing_orders tbody tr:nth-child(2) input[name='bulk_ids[]']").click

        page.find("span.icon-reorder", text: "Actions").click
        within ".ofn-drop-down .menu" do
          page.find("span", text: "Cancel Orders").click
        end

        expect(page).to have_content "Are you sure you want to proceed?"
        expect(page).to have_content "This will cancel the current order."

        within ".reveal-modal" do
          uncheck "Send a cancellation email to the customer"
          expect {
            click_on "Cancel" # Cancels the cancel action
          }.not_to enqueue_mail
        end

        expect(page).not_to have_content "This will cancel the current order."

        page.find("span.icon-reorder", text: "Actions").click
        within ".ofn-drop-down .menu" do
          page.find("span", text: "Cancel Orders").click
        end

        expect {
          within ".reveal-modal" do
            click_on "Confirm" # Confirms the cancel action
          end
          expect(page).to have_content("CANCELLED", count: 2)
        }.to enqueue_job(AmendBackorderJob).exactly(:twice)
          # You can't combine negative matchers.
          .and enqueue_mail.exactly(0).times
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

        page.find("span.icon-reorder", text: "Actions").click
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

  def extract_pdf_content
    # Extract last part of invoice URL
    link = page.find(class: "button", text: "View File")
    filename = link[:href].match %r{/invoices/.*}

    # Load invoice temp file directly instead of downloading
    reader = PDF::Reader.new("tmp/#{filename}.pdf")
    reader.pages.map(&:text)
  end

  def print_all_invoices
    page.find("span.icon-reorder", text: "Actions").click
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
  end
end
