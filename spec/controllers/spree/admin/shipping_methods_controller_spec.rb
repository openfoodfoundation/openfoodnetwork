require 'spec_helper'

describe Spree::Admin::ShippingMethodsController, type: :controller do
  include AuthenticationWorkflow

  describe "shipping method not referenced by order" do
    let(:shipping_method) { create(:shipping_method) }

    scenario "is soft deleted" do
      login_as_admin
      expect(shipping_method.deleted_at).to be_nil

      spree_delete :destroy, "id" => shipping_method.id

      expect(shipping_method.reload.deleted_at).not_to be_nil
    end
  end

  describe "shipping method referenced by order" do
    let(:order) { create(:order_with_line_items) }

    scenario "is not soft deleted" do
      login_as_admin
      expect(order.shipping_method.deleted_at).to be_nil

      spree_delete :destroy, "id" => order.shipping_method.id

      expect(order.shipping_method.reload.deleted_at).to be_nil
    end
  end
end
