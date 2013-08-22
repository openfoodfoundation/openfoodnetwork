require 'spec_helper'

describe Spree::Admin::ReportsController do

  # Given two distributors
  let (:ba) { create(:address) }
  let (:da) { create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234") }
  let (:si) { "pick up on thursday please" }
  let (:d1) { create(:distributor_enterprise, address: da) }
  let (:d2) { create(:distributor_enterprise, address: da) }
  let (:p1) { create(:product, price: 12.34, distributors: [d1]) }
  let (:p2) { create(:product, price: 23.45, distributors: [d2]) }

  # Given two order cycles with both distributors
  let (:ocA) { create(:order_cycle, distributors: [d1, d2], variants:[p1.master]) }
  let (:ocB) { create(:order_cycle, distributors: [d1, d2], variants: [p2.master]) }

  let (:orderA1) do
    order = create(:order, distributor: d1, bill_address: ba, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p1.master)
    order.finalize!
    order
  end
  let (:orderA2) do
    order = create(:order, distributor: d2, bill_address: ba, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order
  end
  let (:orderB1) do
    order = create(:order, distributor: d1, bill_address: ba, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p1.master)
    order.finalize!
    order
  end
  let (:orderB2) do
    order = create(:order, distributor: d2, bill_address: ba, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order
  end
  
  # Given Distributor Enterprise user for d1
  let (:user) do
    user = create(:user)
    user.spree_roles = []
    s1.enterprise_roles.build(user: user, enterprises: [d1]).save
    user
  end

  describe 'Orders and Distributors' do
    spree_get :orders_and_distributors

    controller.search.result.should_include [orderA1, orderB1]
    # assigns(:search).result.should_include [orderA1, orderB1]
  end
end
