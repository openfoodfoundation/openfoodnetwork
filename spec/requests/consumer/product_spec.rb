require 'spec_helper'

feature %q{
    As a consumer
    I want to see products
    So that I can shop
} do
  include AuthenticationWorkflow
  include WebHelper

  scenario "viewing a product shows its supplier and distributor" do
    # Given a product with a supplier and distributor
    s = create(:supplier_enterprise)
    d = create(:distributor_enterprise)
    p = create(:product, :supplier => s, :distributors => [d])

    # When I view the product
    visit spree.product_path p

    # Then I should see the product's supplier and distributor
    page.should have_selector 'td', :text => s.name
    page.should have_selector 'td', :text => d.name
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
           d.address.address1,
           d.address.city,
           d.address.zipcode,
           d.address.state_text,
           d.address.country.name,
           d.pickup_times,
           d.next_collection_at,
           d.contact,
           d.phone,
           d.email,
           d.description,
           d.website].each do |value|

            page.should have_content value
          end
        end
      end
    end

    context "with Javascript", js: true do
      it "changes distributor details when the distributor is changed" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        d3 = create(:distributor_enterprise)
        p = create(:product, :distributors => [d1, d2, d3])

        visit spree.product_path p

        [d1, d2, d3].each do |d|
          select d.name, :from => 'distributor_id'

          within '#product-distributor-details' do
            page.should have_selector 'h2', :text => d.name
          end
        end
      end
    end
  end
end
