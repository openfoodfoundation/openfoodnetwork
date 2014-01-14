require 'spec_helper'

feature %q{
    As a consumer
    I want to see products
    So that I can shop
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing a product shows its supplier" do
    # Given a product with a supplier and distributor
    s = create(:supplier_enterprise)
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
    p = create(:product, :supplier => s, :distributors => [d1])
    oc = create(:simple_order_cycle, :distributors => [d2], :variants => [p.master])

    # When I view the product
    visit spree.product_path p

    # Then I should see the product's supplier
    page.should have_selector 'td', :text => s.name
  end

  describe "viewing distributor details" do
    context "without Javascript" do
      it "displays a holding message when no distributor is selected" do
        p = create(:product)

        visit spree.product_path p

        page.should have_selector '#product-distributor-details', :text => 'When you select a distributor for your order, their address and pickup times will be displayed here.'
      end

      it "displays distributor details when one is selected" do
        d = create(:distributor_enterprise)
        p = create(:product, :distributors => [d])

        visit spree.select_distributor_order_path(d)
        visit spree.product_path p

        within '#product-distributor-details' do
          [d.name,
           d.distributor_info,
           d.next_collection_at
          ].each do |value|

            page.should have_content value
          end
        end
      end
    end
  end
end
