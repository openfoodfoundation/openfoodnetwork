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
      user: supplier1_ent_user, line_items_count: 1
    )
    o.line_items.first.update_columns(variant_id: supplier1_v1.id)
    o
  end

  let(:supplier1_ent_user) { create(:user, enterprises: [supplier1]) }

  context "As supplier1 enterprise user" do
    before { login_as(supplier1_ent_user) }
    let(:order) { order_containing_supplier1_products }
    let(:user) { supplier1_ent_user }

    describe 'bulk orders index page' do
      before { visit spree.admin_bulk_order_management_path }

      context "when no distributor allow the producer to edit orders" do
        let(:distributor) { create(:distributor_enterprise) }

        it "should not allow producer to view orders page" do
          expect(page).to have_content 'Unauthorized'
        end
      end

      context "when distributor allows the producer to edit orders" do
        let(:distributor) { create(:distributor_enterprise, enable_producers_to_edit_orders: true) }

        context "when distributor doesn't allow to view customer details" do
          it "should allow producer to view bulk orders page with HIDDEN customer details" do
            within('tbody') do
              expect(page).to have_selector('tr', count: 1)
              expect(page).to have_selector('td', text: '< Hidden >', count: 1)
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
          it "should allow producer to view bulk orders page with customer details" do
            within('tbody') do
              expect(page).to have_selector('tr', count: 1)
              expect(page).to have_selector('td', text: order.bill_address.full_name_for_sorting,
                                                  count: 1)
            end
          end
        end
      end
    end
  end
end
