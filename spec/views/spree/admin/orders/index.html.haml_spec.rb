# frozen_string_literal: true

require "spec_helper"

describe "spree/admin/orders/index.html.haml" do
  helper Spree::Admin::NavigationHelper
  helper EnterprisesHelper

  around do |example|
    original_config = Spree::Config[:enable_invoices?]
    example.run
    Spree::Config[:enable_invoices?] = original_config
  end

  before do
    controller.singleton_class.class_eval do
      def current_ability
        Spree::Ability.new(Spree.user_class.new)
      end
    end

    allow(view).to receive_messages spree_current_user: create(:user)
  end

  describe "print invoices button" do
    it "displays button when invoices are enabled" do
      Spree::Config[:enable_invoices?] = true

      render

      expect(rendered).to have_content("Print Invoices")
    end

    it "does not display button when invoices are disabled" do
      Spree::Config[:enable_invoices?] = false

      render

      expect(rendered).to_not have_content("Print Invoices")
    end
  end
end
