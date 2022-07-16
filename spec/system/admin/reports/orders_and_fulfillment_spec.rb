# frozen_string_literal: true

require "system_helper"

describe "Orders And Fulfillment" do
  include AuthenticationHelper
  include WebHelper

  describe "reports" do
    before do
      login_as_admin
      visit admin_reports_path
    end

    let(:bill_address1) { create(:address, lastname: "ABRA") }
    let(:bill_address2) { create(:address, lastname: "KADABRA") }
    let(:distributor_address) {
      create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234")
    }
    let(:distributor) { create(:distributor_enterprise, address: distributor_address) }
    let(:order1) {
      create(:completed_order_with_totals, line_items_count: 0, distributor: distributor,
                                           bill_address: bill_address1)
    }
    let(:order2) {
      create(:completed_order_with_totals, line_items_count: 0, distributor: distributor,
                                           bill_address: bill_address1)
    }
    let(:supplier) { create(:supplier_enterprise, name: "Supplier") }
    let(:product) { create(:simple_product, name: "Product", supplier: supplier ) }
    let(:variant) { create(:variant, product: product, unit_description: "Big") }

    before do
      Timecop.travel(Time.zone.local(2022, 4, 25, 14, 0, 0)) { order1.finalize! }
      Timecop.travel(Time.zone.local(2022, 4, 25, 15, 0, 0)) { order2.finalize! }

      create(:line_item_with_shipment, variant: variant, quantity: 1, order: order1)
      create(:line_item_with_shipment, variant: variant, quantity: 2, order: order2)
    end

    describe "Order Cycle Customer Totals" do
      before do
        click_link "Order Cycle Customer Totals"
      end

      it "displays the report" do
        find('#q_completed_at_gt').click
        select_date_from_datepicker Time.zone.at(order1.completed_at - 1.day)

        find('#q_completed_at_lt').click
        select_date_from_datepicker Time.zone.at(order2.completed_at + 1.day)

        click_button 'Go'

        rows = find("table.report__table").all("thead tr")
        table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
        expect(table).to eq([
                              [I18n.t("report_header_hub"),
                               I18n.t("report_header_customer"),
                               I18n.t("report_header_email"),
                               I18n.t("report_header_phone"),
                               I18n.t("report_header_producer"),
                               I18n.t("report_header_product"),
                               I18n.t("report_header_variant"),
                               I18n.t("report_header_quantity"),
                               I18n.t("report_header_item_price", currency: currency_symbol),
                               I18n.t("report_header_item_fees_price", currency: currency_symbol),
                               I18n.t("report_header_admin_handling_fees",
                                      currency: currency_symbol),
                               I18n.t("report_header_ship_price", currency: currency_symbol),
                               I18n.t("report_header_pay_fee_price", currency: currency_symbol),
                               I18n.t("report_header_total_price", currency: currency_symbol),
                               I18n.t("report_header_paid"),
                               I18n.t("report_header_shipping"),
                               I18n.t("report_header_delivery"),
                               I18n.t("report_header_ship_street"),
                               I18n.t("report_header_ship_street_2"),
                               I18n.t("report_header_ship_city"),
                               I18n.t("report_header_ship_postcode"),
                               I18n.t("report_header_ship_state"),
                               I18n.t("report_header_comments"),
                               I18n.t("report_header_sku"),
                               I18n.t("report_header_order_cycle"),
                               I18n.t("report_header_payment_method"),
                               I18n.t("report_header_customer_code"),
                               I18n.t("report_header_tags"),
                               I18n.t("report_header_billing_street"),
                               I18n.t("report_header_billing_street_2"),
                               I18n.t("report_header_billing_city"),
                               I18n.t("report_header_billing_postcode"),
                               I18n.t("report_header_billing_state"),
                               I18n.t("report_header_order_number"),
                               I18n.t("report_header_date")]
                                            .map(&:upcase)
                            ])
      end

      it "pre selects the last order cycle when it exists" do
        order_cycle = create(:simple_order_cycle, distributors: [distributor])

        visit current_path

        expect(find('#q_order_cycle_id_in').value).to eq [order_cycle.id.to_s]
      end

      it "handles order cycles with nil opening or closing times" do
        distributor = create(:distributor_enterprise)
        oc = create(:simple_order_cycle, name: "My Order Cycle", distributors: [distributor],
                                         orders_open_at: Time.zone.now, orders_close_at: nil)
        o = create(:order, order_cycle: oc, distributor: distributor)

        click_button 'Go'

        expect(page).to have_content "My Order Cycle"
      end

      context "with two orders on the same day at different times" do
        let(:bill_address) { create(:address) }
        let(:distributor_address) {
          create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234")
        }
        let(:distributor) { create(:distributor_enterprise, address: distributor_address) }
        let(:product) { create(:product) }
        let(:shipping_instructions) { "pick up on thursday please!" }
        let(:order1) {
          create(:order, distributor: distributor, bill_address: bill_address,
                         special_instructions: shipping_instructions)
        }
        let(:order2) {
          create(:order, distributor: distributor, bill_address: bill_address,
                         special_instructions: shipping_instructions)
        }

        let(:completed_at1) { Time.zone.now - 1500.hours } # 1500 hours in the past
        let(:completed_at2) { Time.zone.now - 1510.hours } # 1510 hours in the past
        let(:datetime_start) { Time.zone.now - 1600.hours } # 1600 hours in the past
        let(:datetime_end) { Time.zone.now - 1400.hours } # 1400 hours in the past

        before do
          Timecop.travel(completed_at1) { order1.finalize! }
          Timecop.travel(completed_at2) { order2.finalize! }

          create(:line_item_with_shipment, product: product, order: order1)
          create(:line_item_with_shipment, product: product, order: order2)
        end

        it "is precise to time of day, not just date" do
          # When I generate a customer report
          # with a timeframe that includes one order but not the other

          pick_datetime "#q_completed_at_gt", datetime_start
          pick_datetime "#q_completed_at_lt", datetime_end

          select 'Order Cycle Customer Totals', from: 'report_subtype'
          find("#display_summary_row").set(false) # hides the summary rows
          click_button 'Go'
          # Then I should see the rows for the first order but not the second
          expect(all('table.report__table tbody tr').count).to eq(4) # Two rows per order

          find("#display_summary_row").set(true) # displays the summary rows
          click_button 'Go'
          # Then I should see the rows for the first order but not the second
          expect(all('table.report__table tbody tr').count).to eq(6)
          # Two rows per order + two summary rows
        end
      end
    end
  end
end
