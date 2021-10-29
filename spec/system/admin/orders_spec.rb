# frozen_string_literal: true

require "system_helper"

describe '
    As an administrator
    I want to manage orders
', js: true do
  include AuthenticationHelper
  include WebHelper

  let(:user) { create(:user) }
  let(:product) { create(:simple_product) }
  let(:distributor) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:distributor2) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:distributor3) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:distributor4) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor, distributor2, distributor3, distributor4],
                                variants: [product.variants.first])
  end

  context "with a complete order" do
    let(:order) do
      create(:order_with_totals_and_distribution, user: user, distributor: distributor,
                                                  order_cycle: order_cycle,
                                                  state: 'complete', payment_state: 'balance_due')
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

    let!(:order2) {
      create(:order_with_credit_payment, user: user, distributor: distributor2,
                                         order_cycle: order_cycle2, completed_at: 2.days.ago)
    }
    let!(:order3) {
      create(:order_with_credit_payment, user: user, distributor: distributor3,
                                         order_cycle: order_cycle3)
    }
    let!(:order4) {
      create(:order_with_credit_payment, user: user, distributor: distributor4,
                                         order_cycle: order_cycle4)
    }

    it "order cycles appear in descending order by close date on orders page" do
      login_as_admin_and_visit 'admin/orders'

      open_select2('#s2id_q_order_cycle_id_in')

      expect(find('#q_order_cycle_id_in',
                  visible: :all)[:innerHTML]).to have_content(/.*Four.*Three.*Two/m)
    end

    it "filter by multiple order cycles" do
      login_as_admin_and_visit 'admin/orders'

      select2_select 'Two', from: 'q_order_cycle_id_in'
      select2_select 'Three', from: 'q_order_cycle_id_in'

      page.find('.filter-actions .button.icon-search').click

      # Order 2 and 3 should show, but not 4
      expect(page).to have_content order2.number
      expect(page).to have_content order3.number
      expect(page).to_not have_content order4.number
    end

    it "filter by distributors" do
      login_as_admin_and_visit 'admin/orders'

      select2_select distributor2.name.to_s, from: 'q_distributor_id_in'
      select2_select distributor4.name.to_s, from: 'q_distributor_id_in'

      page.find('.filter-actions .button.icon-search').click

      # Order 2 and 4 should show, but not 3
      expect(page).to have_content order2.number
      expect(page).to_not have_content order3.number
      expect(page).to have_content order4.number
    end

    it "filter by complete date" do
      login_as_admin_and_visit 'admin/orders'

      find('#q_completed_at_gteq').click
      select_date_from_datepicker order3.completed_at.yesterday
      find('#q_completed_at_lteq').click
      select_date_from_datepicker order4.completed_at.tomorrow

      page.find('.filter-actions .button.icon-search').click

      # Order 3 and 4 should show, but not 2
      expect(page).to_not have_content order2.number
      expect(page).to have_content order3.number
      expect(page).to have_content order4.number
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
        expect(page).to have_button('Print Invoices', disabled: false)
        # unselect all orders
        page.find("#listing_orders thead th:first-child input[type=checkbox]").click
        expect(page.find("#listing_orders tbody tr td:first-child input[type=checkbox]")).to_not be_checked
        # disables print invoices button
        expect(page).to have_button('Print Invoices', disabled: true)
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
        user: user,
        state: 'complete',
        payment_state: 'balance_due',
        completed_at: 1.day.ago,
        line_items_count: 1
      )

      empty_complete_order = create(
        :order_with_line_items,
        distributor: distributor,
        order_cycle: order_cycle,
        user: user,
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
      find('#q_completed_at_gteq').click
      select_date_from_datepicker Time.zone.at(1.week.ago)
      find('#q_completed_at_lteq').click
      select_date_from_datepicker Time.zone.now.tomorrow

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
      expect(find("#q_completed_at_gteq").value).to eq 1.week.ago.strftime("%Y-%m-%d")
      expect(find("#q_completed_at_lteq").value).to eq Time.zone.now.tomorrow.strftime("%Y-%m-%d")
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
      expect(find("#q_completed_at_gteq").value).to be_empty
      expect(find("#q_completed_at_lteq").value).to be_empty
    end
  end
end
