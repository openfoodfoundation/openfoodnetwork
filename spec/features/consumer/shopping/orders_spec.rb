require 'spec_helper'

feature "Order Management", js: true do
  include AuthenticationWorkflow

  describe "editing a completed order" do
    let(:address) { create(:address) }
    let(:user) { create(:user, bill_address: address, ship_address: address) }
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true, charges_sales_tax: true) }
    let(:order_cycle) { create(:order_cycle) }
    let(:shipping_method) { distributor.shipping_methods.first }
    let(:order) { create(:completed_order_with_totals, order_cycle: order_cycle, distributor: distributor, user: user, bill_address: address, ship_address: address) }
    let!(:item1) { order.reload.line_items.first }
    let!(:item2) { create(:line_item, order: order) }
    let!(:item3) { create(:line_item, order: order) }

    before do
      shipping_method.calculator.update_attributes(preferred_amount: 5.0)
      order.update_attributes(shipping_method_id: shipping_method.id)
      order.reload.save
      quick_login_as user
    end

    context "when the distributor doesn't allow changes to be made to orders" do
      before do
        order.distributor.update_attributes(allow_order_changes: false)
      end

      it "doesn't show form elements for editing the order" do
        visit spree.order_path(order)
        expect(find("tr.variant-#{item1.variant.id}")).to have_content item1.product.name
        expect(find("tr.variant-#{item2.variant.id}")).to have_content item2.product.name
        expect(find("tr.variant-#{item3.variant.id}")).to have_content item3.product.name
        expect(page).to_not have_button I18n.t(:save_changes)
      end
    end

    context "when the distributor allows changes to be made to orders" do
      before do
        Spree::MailMethod.create!(
          environment: Rails.env,
          preferred_mails_from: 'spree@example.com'
        )
      end
      before do
        order.distributor.update_attributes(allow_order_changes: true)
      end

      it "allows quantity to be changed, items to be removed and the order to be cancelled" do
        visit spree.order_path(order)

        expect(page).to have_button I18n.t(:order_saved), disabled: true
        expect(page).to_not have_button I18n.t(:save_changes)

        # Changing the quantity of an item
        within "tr.variant-#{item1.variant.id}" do
          expect(page).to have_content item1.product.name
          expect(page).to have_field 'order_line_items_attributes_0_quantity'
          fill_in 'order_line_items_attributes_0_quantity', with: 2
        end

        expect(page).to have_button I18n.t(:save_changes)

        expect(find("tr.variant-#{item2.variant.id}")).to have_content item2.product.name
        expect(find("tr.variant-#{item3.variant.id}")).to have_content item3.product.name
        expect(find("tr.order-adjustment")).to have_content "Shipping"
        expect(find("tr.order-adjustment")).to have_content "$5.00"

        click_button I18n.t(:save_changes)

        expect(find(".order-total.grand-total")).to have_content "$45.00"
        expect(item1.reload.quantity).to eq 2

        # Deleting an item
        within "tr.variant-#{item2.variant.id}" do
          click_link "delete_line_item_#{item2.id}"
        end

        expect(find(".order-total.grand-total")).to have_content "$35.00"
        expect(Spree::LineItem.find_by_id(item2.id)).to be nil

        # Cancelling the order
        click_link(I18n.t(:cancel_order))
        expect(page).to have_content I18n.t(:orders_show_cancelled)
        expect(order.reload).to be_canceled
      end
    end
  end
end
