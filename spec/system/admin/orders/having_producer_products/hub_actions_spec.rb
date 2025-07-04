# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
  As a hub (producer seller) who have the ability to update
  orders having their products
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let!(:hub1) { create(:distributor_enterprise, name: 'My hub1') }
  let!(:hub1_v1) { create(:variant, supplier: hub1) }
  let!(:hub1_v2) { create(:variant, supplier: hub1) }
  let(:order_cycle) do
    create(
      :simple_order_cycle,
      distributors: [distributor],
      variants: [hub1_v1, hub1_v2],
      coordinator: distributor
    )
  end
  let!(:order_containing_hub1_products) do
    o = create(
      :completed_order_with_totals,
      distributor:, order_cycle:,
      line_items_count: 1
    )
    o.line_items.first.update_columns(variant_id: hub1_v1.id)
    o
  end
  let(:hub1_ent_user) { create(:user, enterprises: [hub1]) }

  context "As hub1 enterprise user" do
    before { login_as(hub1_ent_user) }
    let(:order) { order_containing_hub1_products }
    let(:user) { hub1_ent_user }

    describe 'orders index page' do
      before { visit spree.admin_orders_path }

      context "when no distributor allow the producer to edit orders" do
        let(:distributor) { create(:distributor_enterprise) }

        it "does not allow producer to view orders page" do
          expect(page).to have_content 'NO ORDERS FOUND'
        end
      end

      context "when distributor allows the producer to edit orders" do
        let(:distributor) { create(:distributor_enterprise, enable_producers_to_edit_orders: true) }

        context "when distributor doesn't allow to view customer details" do
          it "allows producer to view orders page with HIDDEN customer details" do
            within('#listing_orders tbody') do
              expect(page).to have_selector('tr', count: 1) # Only one order
              # One for Email, one for Name
              expect(page).to have_selector('td', text: '< Hidden >', count: 2)
            end
          end
        end

        context "when distributor allows to view customer details" do
          let(:distributor) do
            create(
              :distributor_enterprise,
              enable_producers_to_edit_orders: true,
              show_customer_names_to_suppliers: true
            )
          end
          it "allows producer to view orders page with customer details" do
            within('#listing_orders tbody') do
              name = order.bill_address&.full_name_for_sorting
              email = order.email
              expect(page).to have_selector('tr', count: 1) # Only one order
              expect(page).to have_selector('td', text: name, count: 1)
              expect(page).to have_selector('td', text: email, count: 1)
              within 'td.actions' do
                # to have edit button
                expect(page).to have_selector("a.icon-edit")
                # not to have ship button
                expect(page).not_to have_selector('button.icon-road')
              end
            end
          end
        end
      end
    end

    describe 'orders edit page' do
      before { visit spree.edit_admin_order_path(order) }

      context "when no distributor allow the producer to edit orders" do
        let(:distributor) { create(:distributor_enterprise) }

        it "does not allow producer to view orders page" do
          expect(page).to have_content 'Unauthorized'
        end
      end

      context "when distributor allows to edit orders" do
        let(:distributor) { create(:distributor_enterprise, enable_producers_to_edit_orders: true) }
        let(:product) { hub1_v2.product }

        it "allows me to manage my products in the order" do
          expect(page).to have_content 'Add Product'

          # Add my product
          add_product(product)
          expect_product_change(product, :add)

          # Edit my product
          edit_product(product)
          expect_product_change(product, :update, 2)

          # Delete my product
          delete_product(product)
          expect_product_change(product, :remove)
        end
      end

      def expect_product_change(product, action, expected_qty = 0)
        # JS for this page sometimes take more than 2 seconds (default timeout for cappybara)
        timeout = 5

        within('table.index tbody tr', wait: timeout) do
          case action
          when :add
            expect(page).to have_text(product.name, wait: timeout)
          when :update
            expect(page).to have_text(expected_qty.to_s, wait: timeout)
          when :remove
            expect(page).not_to have_text(product.name, wait: timeout)
          else
            raise 'Invalid action'
          end
        end
      end

      def add_product(product)
        select2_select product.name, from: 'add_variant_id', search: true
        find('button.add_variant').click
      end

      def edit_product(product)
        find('a.edit-item.icon_link.icon-edit.no-text.with-tip').click
        fill_in 'quantity', with: 2
        find("a[data-variant-id='#{product.variants.last.id}'][data-action='save']").click
      end

      def delete_product(product)
        find("a[data-variant-id='#{product.variants.last.id}'][data-action='remove']").click
        click_button 'OK'
      end
    end
  end
end
