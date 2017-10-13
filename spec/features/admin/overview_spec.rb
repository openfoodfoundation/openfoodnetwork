require 'spec_helper'

feature %q{
  As a backend user
  I want to be given information about the state of my enterprises, products and order cycles
}, js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ::Spree::TestingSupport::AuthorizationHelpers

  context "as an enterprise user" do
    before do
      @enterprise_user = create_enterprise_user
      Spree::Admin::OverviewController.any_instance.stub(:spree_current_user).and_return @enterprise_user
      quick_login_as @enterprise_user
    end

    context "with an enterprise" do
      let(:d1) { create(:distributor_enterprise) }

      before :each do
        @enterprise_user.enterprise_roles.build(enterprise: d1).save
      end

      it "displays a link to the map page" do
        visit '/admin'
        page.should have_selector ".dashboard_item h3", text: "Your profile live"
        page.should have_selector ".dashboard_item .button.bottom", text: "SEE #{d1.name.upcase} LIVE"
      end

      context "when enterprise has not been confirmed" do
        before do
          d1.confirmed_at = nil
          d1.save!
        end

        it "displays a message telling to user to confirm" do
          visit '/admin'
          page.should have_selector ".alert-box", text: "Please confirm the email address for #{d1.name}. We've sent an email to #{d1.email}."
        end
      end

      context "when visibilty is set to false" do
        before do
          d1.visible = false
          d1.save!
        end

        it "displays a message telling how to set visibility" do
          visit '/admin'
          page.should have_selector ".alert-box", text: "To allow people to find you, turn on your visibility under Manage #{d1.name}."
        end
      end

      pending "when user is a profile only" do
        before do
          d1.sells = "none"
          d1.save!
        end

        it "does not show a products item" do
          visit '/admin'
          page.should_not have_selector "#products"
        end
      end
    end

    context "with multiple enterprises" do
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }

      before :each do
        @enterprise_user.enterprise_roles.build(enterprise: d1).save
        @enterprise_user.enterprise_roles.build(enterprise: d2).save
      end

      it "displays information about the enterprise" do
        visit '/admin'
        page.should have_selector ".dashboard_item#enterprises h3", text: "My Enterprises"
        page.should have_selector ".dashboard_item#products"
        page.should have_selector ".dashboard_item#order_cycles"
        page.should have_selector ".dashboard_item#enterprises .list-item", text: d1.name
        page.should have_selector ".dashboard_item#enterprises .button.bottom", text: "MANAGE MY ENTERPRISES"
      end

      context "but no products or order cycles" do
        it "prompts the user to create a new product and to manage order cycles" do
          visit '/admin'
          page.should have_selector ".dashboard_item#products h3", text: "Products"
          page.should have_selector ".dashboard_item#products .list-item", text: "You don't have any active products."
          page.should have_selector ".dashboard_item#products .button.bottom", text: "CREATE A NEW PRODUCT"
          page.should have_selector ".dashboard_item#order_cycles h3", text: "Order Cycles"
          page.should have_selector ".dashboard_item#order_cycles .list-item", text: "You don't have any active order cycles."
          page.should have_selector ".dashboard_item#order_cycles .button.bottom", text: "MANAGE ORDER CYCLES"
        end
      end

      context "and at least one product and active order cycle" do
        let(:oc1) { create(:simple_order_cycle, distributors: [d1]) }
        let(:p1) { create(:product, distributor: d1) }

        it "displays information about products and order cycles" do
          visit '/admin'
          page.should have_selector ".dashboard_item#products h3", text: "Products"
          page.should have_selector ".dashboard_item#products .list-item", text: "You don't have any active products."
          page.should have_selector ".dashboard_item#products .button.bottom", text: "CREATE A NEW PRODUCT"
          page.should have_selector ".dashboard_item#order_cycles h3", text: "Order Cycles"
          page.should have_selector ".dashboard_item#order_cycles .list-item", text: "You don't have any active order cycles."
          page.should have_selector ".dashboard_item#order_cycles .button.bottom", text: "MANAGE ORDER CYCLES"
        end
      end
    end

    context "with the spree dash configured" do
      let(:d1) { create(:distributor_enterprise) }

      before do
        stub_jirafe
        @enterprise_user.enterprise_roles.build(enterprise: d1).save
      end

      around do |example|
        with_dash_configured { example.run }
      end

      it "has permission to sync analytics" do
        visit '/admin'
        expect(page).to have_content d1.name
      end
    end
  end

  private

  def stub_jirafe
    stub_request(:post, "https://api.jirafe.com/v1/applications/abc123/resources?token=").
      to_return(:status => 200, :body => "", :headers => {})
  end

  def with_dash_configured(&block)
    Spree::Dash::Config.preferred_app_id = 'abc123'
    Spree::Dash::Config.preferred_site_id = 'abc123'
    Spree::Dash::Config.preferred_token = 'abc123'
    expect(Spree::Dash::Config.configured?).to be true

    block.call

  ensure
    Spree::Dash::Config.preferred_app_id = nil
    Spree::Dash::Config.preferred_site_id = nil
    Spree::Dash::Config.preferred_token = nil
    expect(Spree::Dash::Config.configured?).to be false
  end
end
