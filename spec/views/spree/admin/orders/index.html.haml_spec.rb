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
        Spree::Ability.new(Spree::User.new)
      end
    end

    allow(view).to receive_messages spree_current_user: create(:user)
  end

  describe "Bulk order actions" do
    it "display all buttons when invoices are enabled" do
      Spree::Config[:enable_invoices?] = true

      render

      expect(rendered).to have_content("Print Invoices")
      expect(rendered).to have_content("Resend Confirmation")
      expect(rendered).to have_content("Cancel Orders")
    end

    it "does not display print button when invoices are disabled but others remain" do
      Spree::Config[:enable_invoices?] = false

      render

      expect(rendered).to_not have_content("Print Invoices")
      expect(rendered).to have_content("Resend Confirmation")
      expect(rendered).to have_content("Cancel Orders")
    end
  end
end
