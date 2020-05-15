# frozen_string_literal: true

require "spec_helper"

feature '
    As an administrator
    I want to manage orders
', js: true do
  include AuthenticationWorkflow
  include WebHelper

  let(:user) { create(:user) }
  let(:product) { create(:simple_product) }
  let(:distributor) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor],
                                variants: [product.variants.first])
  end

  context "with a complete order" do
    let(:order) do
      create(:order_with_totals_and_distribution, user: user, distributor: distributor,
                                                  order_cycle: order_cycle,
                                                  state: 'complete', payment_state: 'balance_due')
    end

    scenario "order cycles appear in descending order by close date on orders page" do
      create(:simple_order_cycle, name: 'Two', orders_close_at: 2.weeks.from_now)
      create(:simple_order_cycle, name: 'Four', orders_close_at: 4.weeks.from_now)
      create(:simple_order_cycle, name: 'Three', orders_close_at: 3.weeks.from_now)

      quick_login_as_admin
      visit 'admin/orders'

      open_select2('#s2id_q_order_cycle_id_in')

      expect(find('#q_order_cycle_id_in',
                  visible: :all)[:innerHTML]).to have_content(/.*Four.*Three.*Two/m)
    end

    scenario "filter by multiple order cycles" do
      order_cycle_2 = create(:simple_order_cycle, name: 'Two')
      order_cycle_3 = create(:simple_order_cycle, name: 'Three')
      order_cycle_4 = create(:simple_order_cycle, name: 'Four')

      order_2 = create(:order_with_credit_payment, user: user, distributor: distributor,
                                                  order_cycle: order_cycle_2)
      order_3 = create(:order_with_credit_payment, user: user, distributor: distributor,
                                                  order_cycle: order_cycle_3)
      order_4 = create(:order_with_credit_payment, user: user, distributor: distributor,
                                                  order_cycle: order_cycle_4)

      quick_login_as_admin
      visit 'admin/orders'

      multi_select2_select 'Two', from: 'q_order_cycle_id_in'
      multi_select2_select 'Three', from: 'q_order_cycle_id_in'

      page.find('.filter-actions .button.icon-search').click

      # Order 2 and 3 should show, but not 4
      expect(page).to have_content order_2.number
      expect(page).to have_content order_3.number
      expect(page).to_not have_content order_4.number

    end

    context "with a capturable order" do
      before do
        order.finalize! # ensure order has a payment to capture
        create :check_payment, order: order, amount: order.total
      end

      scenario "capture payment" do
        quick_login_as_admin

        visit spree.admin_orders_path
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

      scenario "ship order from the orders index page" do
        order.payments.first.capture!
        quick_login_as_admin
        visit spree.admin_orders_path

        page.find("[data-powertip=Ship]").click

        expect(page).to have_css "i.success"
        expect(order.reload.shipments.any?(&:shipped?)).to be true
      end
    end
  end

  context "with incomplete order" do
    scenario "can edit order" do
      incomplete_order = create(:order, distributor: distributor, order_cycle: order_cycle)

      quick_login_as_admin

      visit spree.admin_orders_path
      uncheck 'Only show complete orders'
      page.find('a.icon-search').click

      click_icon :edit

      expect(page).to have_current_path spree.edit_admin_order_path(incomplete_order)
    end
  end
end
