require 'spec_helper'

feature "As a consumer I want to view products", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  describe "Viewing a product" do
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:oc1) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now) }
    let(:product) { create(:simple_product, supplier: supplier) }
    let(:variant) { product.variants.first }
    let(:order) { create(:order, distributor: distributor) }
    let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }

    before do
      set_order order
    end

    describe "viewing HTML product descriptions" do
      before do
        exchange1.update_attribute :pickup_time, "monday"
        add_variant_to_order_cycle(exchange1, variant)
      end

      it "shows HTML product description" do
        product.description = "<p><b>Formatted</b> product description.</p>"
        product.save!

        visit shop_path
        select "monday", :from => "order_cycle_id"

        click_link product.name
        expect(page).to have_selector '.reveal-modal'
        modal_should_be_open_for product

        within(".reveal-modal") do
          html.should include("<p><b>Formatted</b> product description.</p>")
        end
      end

      it "does not show unsecure HTML" do
        product.description = "<script>alert('Dangerous!');</script><p>Safe</p>"
        product.save!

        visit shop_path
        select "monday", :from => "order_cycle_id"

        click_link product.name
        expect(page).to have_selector '.reveal-modal'
        modal_should_be_open_for product

        within(".reveal-modal") do
          html.should include("<p>Safe</p>")
          html.should_not include("<script>alert('Dangerous!');</script>")
        end
      end
    end
  end
end
