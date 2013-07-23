require 'spec_helper'

feature 'shipping methods' do
  include AuthenticationWorkflow
  include WebHelper

  before :each do
    login_to_admin_section
    @sm = create(:shipping_method)
  end

  scenario "deleting a shipping method" do
    visit_delete spree.admin_shipping_method_path(@sm)

    page.should have_content "Shipping method \"#{@sm.name}\" has been successfully removed!"
    Spree::ShippingMethod.where(:id => @sm.id).should be_empty
  end

  scenario "deleting a shipping method referenced by an order" do
    o = create(:order)
    o.shipping_method = @sm
    o.save!

    visit_delete spree.admin_shipping_method_path(@sm)

    page.should have_content "That shipping method cannot be deleted as it is referenced by an order: #{o.number}."
    Spree::ShippingMethod.find(@sm.id).should_not be_nil
  end

  scenario "deleting a shipping method referenced by a product distribution" do
    p = create(:product)
    d = create(:distributor_enterprise)
    create(:product_distribution, product: p, distributor: d, shipping_method: @sm)

    visit_delete spree.admin_shipping_method_path(@sm)

    page.should have_content "That shipping method cannot be deleted as it is referenced by a product distribution: #{p.id} - #{p.name}."
    Spree::ShippingMethod.find(@sm.id).should_not be_nil
  end

  scenario "deleting a shipping method referenced by a line item" do
    sm2 = create(:shipping_method)
    d = create(:distributor_enterprise)

    p = create(:product)
    create(:product_distribution, product: p, distributor: d, shipping_method: sm2)

    o = create(:order, distributor: d)
    o.shipping_method = sm2
    o.save!
    li = create(:line_item, order: o, product: p)
    li.shipping_method = @sm
    li.save!

    visit_delete spree.admin_shipping_method_path(@sm)

    page.should have_content "That shipping method cannot be deleted as it is referenced by a line item in order: #{o.number}."
    Spree::ShippingMethod.find(@sm.id).should_not be_nil
  end
end
