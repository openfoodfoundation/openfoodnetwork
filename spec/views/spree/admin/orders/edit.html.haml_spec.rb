# frozen_string_literal: true

require "spec_helper"

describe "spree/admin/orders/edit.html.haml" do
  helper Spree::BaseHelper # required to make pretty_time work
  helper Spree::Admin::NavigationHelper
  helper Admin::InjectionHelper
  helper Admin::OrdersHelper

  around do |example|
    original_config = Spree::Config[:enable_invoices?]
    example.run
    Spree::Config[:enable_invoices?] = original_config
  end

  before do
    controller.singleton_class.class_eval do
      def current_ability
        Spree::Ability.new(Spree::User.new)
      end
    end

    allow(view).to receive_messages spree_current_user: create(:user)
  end

  context "when order is complete" do
    let(:order) { create(:completed_order_with_fees) }

    before do
      order.distributor = create(:distributor_enterprise)
      assign(:order, order)
      assign(:shops, [order.distributor])
      assign(:order_cycles, [])
    end

    describe "order values" do
      it "displays order shipping costs, transaction fee and order total" do
        render

        expect(rendered).to have_content("Shipping Method\nUPS Ground $6.00")
        expect(rendered).to have_content("Transaction fee:\n\n$10.00")
        expect(rendered).to have_content("Order Total\n$36.00")
      end
    end

    context "when some line items are out of stock" do
      let!(:out_of_stock_line_item) do
        line_item = order.line_items.first
        line_item.variant.update!(on_demand: false, on_hand: 0)
        line_item
      end

      it "doesn't display a table of out of stock line items" do
        render

        expect(rendered).to_not have_content "Out of Stock"
        expect(rendered).to_not have_selector ".insufficient-stock-items",
                                              text: out_of_stock_line_item.variant.display_name
      end
    end

    it "doesn't display closed associated adjustments" do
      render

      expect(rendered).to_not have_content "Associated adjustment closed"
    end
  end

  context "when order is incomplete" do
    let(:order) { create(:order_with_line_items) }

    before do
      assign(:order, order)
      assign(:shops, [order.distributor])
      assign(:order_cycles, [])
    end

    context "when some line items are out of stock" do
      let!(:out_of_stock_line_item) do
        line_item = order.line_items.first
        line_item.variant.update!(on_demand: false, on_hand: 0)
        line_item
      end

      it "displays a table of out of stock line items" do
        render

        expect(rendered).to have_content "Out of Stock"
        expect(rendered).to have_selector ".insufficient-stock-items",
                                          text: out_of_stock_line_item.variant.display_name
      end
    end

    context "when all line items are in stock" do
      it "doesn't display a table of out of stock line items" do
        render

        expect(rendered).to_not have_content "Out of Stock"
      end
    end

    it "doesn't display closed associated adjustments" do
      render

      expect(rendered).to_not have_content "Associated adjustment closed"
    end
  end
end
