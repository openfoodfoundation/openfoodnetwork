require 'spec_helper'

feature 'Standing Orders' do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user", js: true do
    let!(:user) { create_enterprise_user(enterprise_limit: 10) }
    let!(:shop) { create(:distributor_enterprise, owner: user) }
    let!(:shop2) { create(:distributor_enterprise, owner: user) }
    let!(:shop_unmanaged) { create(:distributor_enterprise) }

    before { quick_login_as user }

    context 'listing standing orders' do
      let!(:standing_order) { create(:standing_order, shop: shop) }
      let!(:standing_order2) { create(:standing_order, shop: shop2) }
      let!(:standing_order_unmanaged) { create(:standing_order, shop: shop_unmanaged) }

      it "passes the smoke test" do
        visit admin_standing_orders_path

        expect(page).to have_select2 "shop_id", with_options: [shop.name, shop2.name], without_options: [shop_unmanaged.name]

        select2_select shop2.name, from: "shop_id"

        # Loads standing orders for that shop
        expect(page).to have_selector "tr#so_#{standing_order2.id}"
        expect(page).to have_no_selector "tr#so_#{standing_order.id}"
        expect(page).to have_no_selector "tr#so_#{standing_order_unmanaged.id}"
        within "tr#so_#{standing_order2.id}" do
          expect(page).to have_selector "td.customer", text: standing_order2.customer.email
        end
      end
    end

    context 'creating a new standing order' do
      let!(:customer) { create(:customer, enterprise: shop) }
      let!(:product) { create(:product, supplier: shop) }
      let!(:variant) { create(:variant, product: product, unit_value: '100', price: 12.00, option_values: []) }
      let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
      let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now, orders_close_at: 7.days.from_now) }
      let!(:outgoing_exchange) { order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant], enterprise_fees: [enterprise_fee]) }
      let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
      let!(:payment_method) { create(:payment_method, distributors: [shop]) }
      let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }

      it "passes the smoke test" do
        visit new_admin_standing_order_path(shop_id: shop.id)

        select2_select customer.email, from: 'customer_id'
        select2_select schedule.name, from: 'schedule_id'
        select2_select payment_method.name, from: 'payment_method_id'
        select2_select shipping_method.name, from: 'shipping_method_id'

        # No date filled out, so error returned
        click_button('Next')
        expect(page).to have_content 'can\'t be blank'
        expect(page).to have_content 'Oops! Please fill in all of the required fields...'
        fill_in 'begins_at', with: Date.today.strftime('%F')

        click_button('Next')
        expect(page).to have_content 'NAME OR SKU'
        click_button('Next')
        expect(page).to have_content 'Please add at least one product'

        # Adding a product and getting a price estimate
        targetted_select2_search product.name, from: '#add_variant_id', dropdown_css: '.select2-drop'
        fill_in 'add_quantity', with: 2
        click_link 'Add'
        within 'table#standing-line-items tr.item', match: :first do
          expect(page).to have_selector 'td.description', text: "#{product.name} - #{variant.full_name}"
          expect(page).to have_selector 'td.price', text: "$13.75"
          expect(page).to have_input 'quantity', with: "2"
          expect(page).to have_selector 'td.total', text: "$27.50"
        end

        click_button('Next')

        expect{
          click_button('Create Standing Order')
          expect(page).to have_content 'Saved'
        }.to change(StandingOrder, :count).by(1)

        # Prices are shown
        within 'table#standing-line-items tr.item', match: :first do
          expect(page).to have_selector 'td.description', text: "#{product.name} - #{variant.full_name}"
          expect(page).to have_selector 'td.price', text: "$13.75"
          expect(page).to have_input 'quantity', with: "2"
          expect(page).to have_selector 'td.total', text: "$27.50"
        end

        # Basic properties of standing order are set
        standing_order = StandingOrder.last
        expect(standing_order.customer).to eq customer
        expect(standing_order.schedule).to eq schedule
        expect(standing_order.payment_method).to eq payment_method
        expect(standing_order.shipping_method).to eq shipping_method

        # Standing Line Items are created
        expect(standing_order.standing_line_items.count).to eq 1
        standing_line_item = standing_order.standing_line_items.first
        expect(standing_line_item.variant).to eq variant
        expect(standing_line_item.quantity).to eq 2
      end
    end
  end
end
