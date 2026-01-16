# frozen_string_literal: true

require "system_helper"

RSpec.describe '
    As an administrator
    I want to create and edit orders
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
    create(:order_with_totals_and_distribution, user:, distributor:,
                                                order_cycle:, state: 'complete',
                                                payment_state: 'balance_due')
  end
  let(:customer) { order.customer }

  before do
    # ensure order has a payment to capture
    order.finalize!

    create :check_payment, order:, amount: order.total
  end

  def new_order_with_distribution(distributor, order_cycle)
    visit spree.new_admin_order_path
    expect(page).to have_selector('#s2id_order_distributor_id')
    select2_select distributor.name, from: 'order_distributor_id'
    select2_select order_cycle.name, from: 'order_order_cycle_id'
    click_button 'Next'
  end

  context "as an enterprise manager" do
    let(:coordinator1) { create(:distributor_enterprise) }
    let(:coordinator2) { create(:distributor_enterprise) }
    let!(:order_cycle1) { create(:order_cycle, coordinator: coordinator1) }
    let!(:order_cycle2) { create(:simple_order_cycle, coordinator: coordinator2) }
    let!(:supplier1) { order_cycle1.suppliers.first }
    let!(:supplier2) { order_cycle1.suppliers.last }
    let!(:distributor1) { order_cycle1.distributors.first }
    let!(:distributor2) do
      order_cycle1.distributors.reject{ |d| d == distributor1 }.last # ensure d1 != d2
    end
    let(:product) { order_cycle1.products.first }

    before(:each) do
      enterprise_user = create(:user)
      enterprise_user.enterprise_roles.build(enterprise: supplier1).save
      enterprise_user.enterprise_roles.build(enterprise: coordinator1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save

      login_as enterprise_user
    end

    describe "viewing the edit page" do
      let!(:shipping_method_for_distributor1) do
        create(:shipping_method_with, :flat_rate, name: "Normal", amount: 12,
                                                  distributors: [distributor1])
      end
      let!(:order) do
        create(
          :order_with_taxes,
          distributor: distributor1,
          order_cycle: order_cycle1,
          ship_address: create(:address),
          product_price: 110,
          tax_rate_amount: 0.1,
          included_in_price: true,
          tax_rate_name: "Tax 1"
        ).tap do |order|
          # Add a values to the fees
          first_calculator = supplier_enterprise_fee1.calculator
          first_calculator.preferred_amount = 2.5
          first_calculator.save!

          last_calculator = supplier_enterprise_fee2.calculator
          last_calculator.preferred_amount = 7.5
          last_calculator.save!

          # Add all variant to the order cycle for a more realistic scenario
          order.variants.each do |v|
            first_exchange.variants << v
            order_cycle1.cached_outgoing_exchanges.first.variants << v
          end

          variant1 = first_exchange.variants.first
          variant2 = last_exchange.variants.first

          order.contents.add(variant1)
          order.contents.add(variant2)
          # make sure all the fees are applied to the order
          order.recreate_all_fees!

          order.update_order!
        end
      end

      let(:first_exchange) { order_cycle1.cached_incoming_exchanges.first }
      let(:last_exchange) { order_cycle1.cached_incoming_exchanges.last }
      let(:coordinator_fee) { order_cycle1.coordinator_fees.first }
      let(:distributor_fee) { order_cycle1.cached_outgoing_exchanges.first.enterprise_fees.first }
      let(:supplier_enterprise_fee1) { first_exchange.enterprise_fees.first }
      let(:supplier_enterprise_fee2) { last_exchange.enterprise_fees.first }

      before do
        distributor1.update_attribute(:abn, '12345678')

        visit spree.edit_admin_order_path(order)
      end

      it "verifying page contents" do
        # shows a list of line_items
        within('table.index tbody', match: :first) do
          order.line_items.each do |item|
            expect(page).to have_selector "td", match: :first, text: item.full_name
            expect(page).to have_selector "td.item-price", text: item.single_display_amount
            expect(page).to have_selector "input#quantity[value='#{item.quantity}']", visible: false
            expect(page).to have_selector "td.item-total", text: item.display_amount
          end
        end

        # shows the order non-tax adjustments
        within "#order_adjustments" do
          # supplier fees only apply to specific product
          first_exchange.variants.each do |variant|
            expect(page).to have_content(
              "#{variant.name} - #{supplier_enterprise_fee1.name} fee \
              by supplier #{supplier1.name}: $2.50".squish
            )
            expect(page).not_to have_content(
              "#{variant.name} - #{supplier_enterprise_fee2.name} fee \
              by supplier #{supplier2.name}: $7.50".squish
            )
          end

          last_exchange.variants.each do |variant|
            expect(page).to have_content(
              "#{variant.name} - #{supplier_enterprise_fee2.name} fee \
              by supplier #{supplier2.name}: $7.50".squish
            )
            expect(page).not_to have_content(
              "#{variant.name} - #{supplier_enterprise_fee1.name} fee  \
              by supplier #{supplier1.name}: $2.50".squish
            )
          end

          ## Coordinator fee and Distributor fee apply to all product
          order.variants.each do |variant|
            expect(page).to have_content(
              "#{variant.name} - #{coordinator_fee.name} fee \
              by coordinator #{coordinator1.name}: $0.00".squish
            )
            expect(page).to have_content(
              "#{variant.name} - #{distributor_fee.name} fee \
              by distributor #{distributor1.name}: $0.00".squish
            )
          end
        end

        # shows the order total
        expect(page).to have_selector "fieldset#order-total", text: order.display_total

        # shows the order tax adjustments
        within('fieldset', text: 'Line Item Adjustments') do
          expect(page).to have_selector "td", match: :first, text: "Tax 1"
          expect(page).to have_selector "td.total", text: Spree::Money.new(10)
        end

        # shows the dropdown menu" do
        find("#links-dropdown .ofn-drop-down").click
        within "#links-dropdown" do
          expect(page).to have_link "Resend Confirmation",
                                    href: spree.resend_admin_order_path(order)
        end
      end

      context "Resending confirmation email" do
        before do
          visit spree.edit_admin_order_path(order)
          find("#links-dropdown .ofn-drop-down").click
        end

        it "shows the link" do
          expect(page).to have_link "Resend Confirmation",
                                    href: spree.resend_admin_order_path(order)
        end

        it "resends the confirmation email" do
          accept_alert "Are you sure you want to resend the order confirmation email?" do
            click_link "Resend Confirmation"
          end
          expect(page).to have_content "Order email has been resent"
        end
      end

      context "Canceling an order" do
        shared_examples "canceling an order" do
          it "shows the link" do
            expect(page).to have_link "Cancel Order",
                                      href: spree.fire_admin_order_path(order, e: 'cancel')
          end
          it 'cancels the order' do
            within ".ofn-drop-down .menu" do
              expect(page).to have_selector("span", text: "Cancel Order")
              page.find("span", text: "Cancel Order").click
            end
            within '.modal-content' do
              expect {
                find_button("OK").click
              }.to change { order.reload.state }.from('complete').to('canceled')
            end
          end
        end

        context "from order details page" do
          before do
            visit spree.edit_admin_order_path(order)
            find("#links-dropdown .ofn-drop-down").click
          end
          it_behaves_like "canceling an order"
        end

        context "from order's payments" do
          before do
            visit spree.admin_order_payments_path(order)
            find("#links-dropdown .ofn-drop-down").click
          end
          it_behaves_like "canceling an order"
        end

        context "from order's adjustments" do
          before do
            visit spree.admin_order_adjustments_path(order)
            find("#links-dropdown .ofn-drop-down").click
          end
          it_behaves_like "canceling an order"
        end
      end

      context "Check send/print invoice links" do
        shared_examples_for 'can send/print invoices' do
          before do
            visit spree.edit_admin_order_path(order)
            find("#links-dropdown .ofn-drop-down").click
          end

          it 'shows the right links' do
            expect(page).to have_link "Send Invoice", href: spree.invoice_admin_order_path(order)
            expect(page).to have_link "Print Invoice", href: spree.print_admin_order_path(order)
          end

          it 'can send invoices' do
            accept_alert "An invoice for this order will be sent to the customer. " \
                         "Are you sure you want to continue?" do
              click_link "Send Invoice"
            end
            expect(page).to have_content "Invoice email has been sent"
          end
        end

        context "when abn number is not mandatory to send/print invoices" do
          before do
            Spree::Config[:enterprise_number_required_on_invoices?] = false
            distributor1.update_attribute(:abn, "")
          end

          it_should_behave_like 'can send/print invoices'
        end

        context "when abn number is mandatory to send/print invoices" do
          before do
            Spree::Config[:enterprise_number_required_on_invoices?] = true
          end

          context "and a abn numer is set on the distributor" do
            before do
              distributor1.update_attribute(:abn, '12345678')
            end

            it_should_behave_like 'can send/print invoices'
          end

          context "and a abn number is not set on the distributor" do
            before do
              distributor1.update_attribute(:abn, "")
            end

            it "should not display links but a js alert" do
              visit spree.edit_admin_order_path(order)

              find("summary", text: "Actions").click
              expect(page).to have_link "Send Invoice", href: "#"
              expect(page).to have_link "Print Invoice", href: "#"

              message = accept_prompt do
                click_link "Print Invoice"
              end
              expect(message)
                .to eq "#{distributor1.name} must have a valid ABN before invoices can be used."

              find("summary", text: "Actions").click
              message = accept_prompt do
                click_link "Send Invoice"
              end
              expect(message)
                .to eq "#{distributor1.name} must have a valid ABN before invoices can be used."
            end
          end
        end
      end

      context "with different shipping methods" do
        let!(:different_shipping_method_for_distributor1) do
          create(:shipping_method_with, :flat_rate, name: "Different", amount: 15,
                                                    distributors: [distributor1])
        end
        let!(:shipping_method_for_distributor2) do
          create(:shipping_method, name: "Other", distributors: [distributor2])
        end

        it "can edit shipping method" do
          visit spree.edit_admin_order_path(order)

          expect(page).not_to have_content different_shipping_method_for_distributor1.name

          find('.edit-method').click

          expect(page).to have_select2('selected_shipping_rate_id',
                                       with_options: [
                                         shipping_method_for_distributor1.name,
                                         different_shipping_method_for_distributor1.name
                                       ], without_options: [shipping_method_for_distributor2.name])

          select2_select(different_shipping_method_for_distributor1.name,
                         from: 'selected_shipping_rate_id')
          find('.save-method').click

          expect(page).to have_content(
            "Shipping: #{different_shipping_method_for_distributor1.name}"
          )

          within "#order-total" do
            expect(page).to have_content "$239.98"
          end
        end

        context "when the distributor unsupport a shipping method that's selected " \
                "in an existing order " do
          before do
            distributor1.shipping_methods = [shipping_method_for_distributor1,
                                             different_shipping_method_for_distributor1]
            order.shipments.each(&:refresh_rates)
            order.shipment.adjustments.first.open
            order.select_shipping_method(different_shipping_method_for_distributor1)
            order.shipment.adjustments.first.close
            distributor1.shipping_methods = [shipping_method_for_distributor1]
          end

          context "shipment is shipped" do
            before do
              order.shipments.first.update_attribute(:state, 'shipped')
            end

            it "should not change the shipping method" do
              visit spree.edit_admin_order_path(order)
              expect(page).to have_content(
                "Shipping: #{different_shipping_method_for_distributor1.name} $15.00"
              )

              within "#order-total" do
                expect(page).to have_content "$224.98"
              end
            end

            context "when shipping rate is updated" do
              before do
                different_shipping_method_for_distributor1.shipping_rates.first.update!(cost: 16)
              end

              it "should not update the shipping cost" do
                visit spree.edit_admin_order_path(order)
                expect(page).to have_content(
                  "Shipping: #{different_shipping_method_for_distributor1.name} $15.00"
                )

                within "#order-total" do
                  expect(page).to have_content "$224.98"
                end
              end
            end
          end
          context "shipment is pending" do
            before do
              order.shipments.first.ensure_correct_adjustment
              expect(order.shipments.first.state).to eq('pending')
            end

            it "should not replace the selected shipment method" do
              visit spree.edit_admin_order_path(order)
              expect(page).to have_content(
                "Shipping: #{different_shipping_method_for_distributor1.name} $15.00"
              )

              within "#order-total" do
                expect(page).to have_content "$224.98"
              end
            end

            context "when shipping rate is updated" do
              before do
                different_shipping_method_for_distributor1.shipping_rates.first.update!(cost: 16)
              end

              it "should not update the shipping cost" do
                # Since the order is completed, the price is not supposed to be updated
                visit spree.edit_admin_order_path(order)
                expect(page).to have_content(
                  "Shipping: #{different_shipping_method_for_distributor1.name} $15.00"
                )

                within "#order-total" do
                  expect(page).to have_content "$224.98"
                end
              end
            end
          end
        end
      end

      it "can edit and delete tracking number" do
        test_tracking_number = "ABCCBA"
        expect(page).not_to have_content test_tracking_number

        find('.edit-tracking').click
        fill_in "tracking", with: test_tracking_number
        find('.save-tracking').click

        expect(page).to have_content test_tracking_number

        find('.delete-tracking.icon-trash').click
        # Cancel Deletion
        # Check if the alert box shows and after clicking cancel
        # the alert box vanishes and tracking num is still present
        expect(page).to have_content 'Are you sure?'
        find('.cancel').click
        expect(page).not_to have_content 'Are you sure?'
        expect(page).to have_content test_tracking_number

        find('.delete-tracking.icon-trash').click
        expect(page).to have_content 'Are you sure?'
        find('.confirm').click
        expect(page).not_to have_content test_tracking_number
      end

      it "can edit and delete note" do
        test_note = "this is a note"
        expect(page).not_to have_content test_note

        find('.edit-note.icon-edit').click
        fill_in "note", with: test_note
        find('.save-note').click

        expect(page).to have_content test_note

        find('.delete-note.icon-trash').click
        # Cancel Deletion
        # Check if the alert box shows and after clicking cancel
        # the alert box vanishes and note is still present
        expect(page).to have_content 'Are you sure?'
        find('.cancel').click
        expect(page).not_to have_content 'Are you sure?'
        expect(page).to have_content test_note

        find('.delete-note.icon-trash').click
        expect(page).to have_content 'Are you sure?'
        find('.confirm').click
        expect(page).not_to have_content test_note
      end

      it "viewing shipping fees" do
        shipping_fee = order.shipment_adjustments.first

        click_link "Adjustments"

        expect(page).to have_selector "tr#spree_adjustment_#{shipping_fee.id}"
        expect(page).to have_selector 'td.amount', text: shipping_fee.amount.to_s
        expect(page).to have_selector 'td.tax', text: shipping_fee.included_tax_total.to_s
      end

      context "shipping orders" do
        before do
          order.finalize! # ensure order has a payment to capture
          order.payments << create(:check_payment, order:, amount: order.total)
          order.payments.first.capture!
          visit spree.edit_admin_order_path(order)
        end

        it "ships the order and shipment email is sent" do
          expect(page).to have_content "ready"
          expect(page).not_to have_content "shipped"
          expect(page).to have_select2 "add_variant_id"

          click_button 'Ship'

          expect {
            within ".reveal-modal" do
              expect(page).to have_checked_field(
                'Send a shipment/pick up notification email to the customer.'
              )
              click_button "Confirm"
            end
            expect(page).to have_content "shipped"
            expect(page).to have_content "Cannot add item to shipped order"
          }.to enqueue_mail
            .and change { order.reload.shipped? }.to true
        end

        it "ships the order without sending email" do
          expect(page).to have_content "ready"
          expect(page).not_to have_content "shipped"

          click_button 'Ship'

          expect {
            within ".reveal-modal" do
              uncheck 'Send a shipment/pick up notification email to the customer.'
              click_button "Confirm"
            end
            expect(page).to have_content "shipped"
          }.to enqueue_mail.exactly(0).times
            .and change { order.reload.shipped? }.to true
        end

        shared_examples "ship order from dropdown" do |subpage|
          context "in the #{subpage}", feature: :invoices do
            it "ships the order and sends email" do
              click_on subpage
              expect(order.reload.shipped?).to be false

              find('.ofn-drop-down').click
              click_link 'Ship Order'

              within ".reveal-modal" do
                expect(page).to have_checked_field('Send a shipment/pick up ' \
                                                   'notification email to the customer.')
                find_button("Confirm").click
              end

              expect(page).not_to have_content("This will mark the order as Shipped.")
              expect(page).to have_content "SHIPPED"
              click_link('Order Details') unless subpage == 'Order Details'

              expect(order.reload.shipped?).to be true
              expect(ActionMailer::MailDeliveryJob).to have_been_enqueued
                .exactly(:once)
                .with("Spree::ShipmentMailer", "shipped_email", "deliver_now",
                      { args: [order.shipment.id, { delivery: true }] })
            end

            it "ships the order without sending email" do
              click_on subpage
              expect(order.reload.shipped?).to be false

              find('.ofn-drop-down').click
              click_link 'Ship Order'

              within ".reveal-modal" do
                uncheck 'Send a shipment/pick up notification email to the customer.'
                find_button("Confirm").click
              end

              expect(page).not_to have_content("This will mark the order as Shipped.")
              click_link('Order Details') unless subpage == 'Order Details'

              expect(page).to have_content "SHIPPED"
              expect(order.reload.shipped?).to be true
              expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued
                .with(array_including("Spree::ShipmentMailer"))
            end
          end
        end

        it_behaves_like "ship order from dropdown", "Order Details"
        it_behaves_like "ship order from dropdown", "Customer Details"
        it_behaves_like "ship order from dropdown", "Payments"
        it_behaves_like "ship order from dropdown", "Adjustments"
        it_behaves_like "ship order from dropdown", "Invoices"
        it_behaves_like "ship order from dropdown", "Return Authorizations"
      end

      context "when an included variant has been deleted" do
        let!(:deleted_variant) do
          order.line_items.first.variant.tap(&:delete)
        end

        it "still lists the variant in the order page" do
          within ".stock-contents" do
            expect(page).to have_content deleted_variant.product_and_full_name
          end
        end
      end

      context "and the order has been canceled" do
        it "does not allow modifying line items" do
          order.cancel!
          visit spree.edit_admin_order_path(order)
          within("tr.stock-item", text: order.products.first.name) do
            expect(page).not_to have_selector("a.edit-item")
          end
        end
      end

      context "when an incomplete order has some line items with insufficient stock" do
        let(:incomplete_order) do
          create(:order_with_line_items, user:, distributor:,
                                         order_cycle:)
        end

        it "displays the out of stock line items and they can be deleted from the order" do
          incomplete_order.line_items.first.variant.update!(on_demand: false, on_hand: 0)

          visit spree.edit_admin_order_path(incomplete_order)

          expect(page).to have_content "Out of Stock"

          within ".insufficient-stock-items" do
            expect(page).to have_content incomplete_order.products.first.name
            accept_alert 'Are you sure?' do
              find("a.delete-resource").click
            end
            expect(page).not_to have_content incomplete_order.products.first.name
          end

          # updates the order and verifies the warning disappears
          click_button "Update And Recalculate Fees"
          expect(page).not_to have_content "Out of Stock"
        end
      end
    end

    it "creating an order with distributor and order cycle" do
      new_order_with_distribution(distributor1, order_cycle1)
      expect(page).to have_selector 'h1', text: 'Customer Details'
      click_link "Order Details"

      expect(page).to have_content 'Add Product'
      select2_select product.name, from: 'add_variant_id', search: true

      find('button.add_variant').click
      page.has_selector? "table.index tbody tr"
      expect(page).to have_selector 'td', text: product.name

      expect(page).to have_select2 'order_distributor_id', with_options: [distributor1.name]
      expect(page).not_to have_select2 'order_distributor_id', with_options: [distributor2.name]

      expect(page).to have_select2 'order_order_cycle_id',
                                   with_options: ["#{order_cycle1.name} (open)"]
      expect(page).not_to have_select2 'order_order_cycle_id',
                                       with_options: ["#{order_cycle2.name} (open)"]

      click_button 'Update'

      o = Spree::Order.last
      expect(o.distributor).to eq distributor1
      expect(o.order_cycle).to eq order_cycle1
    end
  end
end
