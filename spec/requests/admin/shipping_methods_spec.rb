require 'spec_helper'

feature 'shipping methods' do
  include AuthenticationWorkflow
  include WebHelper

  scenario "deleting a shipping method referenced by an order" do
    login_to_admin_section

    sm = create(:shipping_method)
    o = create(:order, shipping_method: sm)

    visit_delete spree.admin_shipping_method_path(sm)

    page.should have_content "That shipping method cannot be deleted as it is referenced by an order: #{o.number}."
    Spree::ShippingMethod.find(sm.id).should_not be_nil
  end

  scenario "deleting a shipping method referenced by a product distribution"
  scenario "deleting a shipping method referenced by a line item"
end
