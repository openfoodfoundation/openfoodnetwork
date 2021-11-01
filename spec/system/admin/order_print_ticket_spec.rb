# frozen_string_literal: true

require "system_helper"

describe '
    As an administrator
    I want to print a ticket for an order
', js: true do
  include CheckoutHelper
  include AuthenticationHelper
  include ActionView::Helpers::NumberHelper

  context "as an enterprise manager" do
    let!(:shipping_method) { create(:shipping_method, distributors: [distributor]) }
    let!(:distributor) { create(:distributor_enterprise) }

    let!(:order) do
      create(:order_with_taxes, distributor: distributor, ship_address: create(:address),
                                product_price: 110, tax_rate_amount: 0.1,
                                tax_rate_name: "Tax 1").tap do |order|
                                  order.create_tax_charge!
                                  order.update_shipping_fees!
                                end
    end

    before do
      @enterprise_user = create(:user)
      @enterprise_user.enterprise_roles.build(enterprise: distributor).save

      login_as @enterprise_user

      Spree::Config[:enable_receipt_printing?] = true
    end

    describe "viewing the edit page" do
      it "can print an order's ticket" do
        visit spree.edit_admin_order_path(order)

        find("#links-dropdown .ofn-drop-down").click

        ticket_window = window_opened_by do
          within('#links-dropdown') do
            click_link('Print Ticket')
          end
        end

        within_window ticket_window do
          accept_alert do
            print_data = page.evaluate_script('printData');
            elements_in_print_data = [
              order.distributor.name,
              order.distributor.address.address_part1,
              order.distributor.address.address_part2,
              order.distributor.contact.email, order.number,
              line_items_in_print_data,
              adjustments_in_print_data,
              order.display_total.format(with_currency: false),
              taxes_in_print_data,
              display_checkout_total_less_tax(order).format(with_currency: false)
            ]
            expect(print_data.join).to include(*elements_in_print_data.flatten)
          end
        end
      end

      def line_items_in_print_data
        order.line_items.map { |line_item|
          [line_item.quantity.to_s,
           line_item.product.name,
           line_item.single_display_amount_with_adjustments.format(symbol: false,
                                                                   with_currency: false),
           line_item.display_amount_with_adjustments.format(symbol: false, with_currency: false)]
        }
      end

      def adjustments_in_print_data
        checkout_adjustments_for(order, exclude: [:line_item]).
          reject { |a| a.amount.zero? }.
          map do |adjustment|
            [raw(adjustment.label),
             display_adjustment_amount(adjustment).format(symbol: false, with_currency: false)]
          end
      end

      def taxes_in_print_data
        display_checkout_taxes_hash(order).map { |tax_rate, tax_value|
          [tax_rate,
           tax_value.format(with_currency: false)]
        }
      end
    end
  end
end
