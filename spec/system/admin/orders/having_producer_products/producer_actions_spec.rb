# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'As a producer who have the ability to update orders' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  let!(:supplier1) { create(:supplier_enterprise, name: 'My supplier1') }
  let!(:supplier2) { create(:supplier_enterprise, name: 'My supplier2') }
  let!(:supplier1_v1) { create(:variant, supplier_id: supplier1.id) }
  let!(:supplier1_v2) { create(:variant, supplier_id: supplier1.id) }
  let!(:supplier2_v1) { create(:variant, supplier_id: supplier2.id) }
  let(:order_cycle) do
    create(:simple_order_cycle, distributors: [distributor], variants: [supplier1_v1, supplier1_v2])
  end
  let!(:order_containing_supplier1_products) do
    o = create(
      :completed_order_with_totals,
      distributor:, order_cycle:,
      line_items_count: 1
    )
    o.line_items.first.update_columns(variant_id: supplier1_v1.id)
    o
  end
  let!(:order_containing_supplier2_v1_products) do
    o = create(
      :completed_order_with_totals,
      distributor:, order_cycle:,
      line_items_count: 1
    )
    o.line_items.first.update_columns(variant_id: supplier2_v1.id)
    o
  end
  let(:supplier1_ent_user) { create(:user, enterprises: [supplier1]) }
  let(:supplier2_ent_user) { create(:user, enterprises: [supplier2]) }

  context "As supplier1 enterprise user" do
    before { login_as(supplier1_ent_user) }
    let(:order) { order_containing_supplier1_products }
    let(:user) { supplier1_ent_user }

    describe 'orders index page' do
      before { visit spree.admin_orders_path }

      context "when no distributor allow the producer to edit orders" do
        let(:distributor) { create(:distributor_enterprise) }

        it "should not allow producer to view orders page" do
          expect(page).to have_content 'Unauthorized'
        end
      end

      context "when distributor allows the producer to edit orders" do
        let(:distributor) { create(:distributor_enterprise, enable_producers_to_edit_orders: true) }
        it "should not allow to add new orders" do
          expect(page).not_to have_link('New Order')
        end

        context "when distributor doesn't allow to view customer details" do
          it "should allow producer to view orders page with HIDDEN customer details" do
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
          it "should allow producer to view orders page with customer details" do
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

        it "should not allow producer to view orders page" do
          expect(page).to have_content 'Unauthorized'
        end
      end

      context "when distributor allows to edit orders" do
        let(:distributor) { create(:distributor_enterprise, enable_producers_to_edit_orders: true) }
        let(:product) { supplier1_v2.product }

        it "should allow me to manage my products in the order" do
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
