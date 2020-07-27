require 'spec_helper'

describe Spree::Admin::ShippingMethodsController, type: :controller do
  include AuthenticationHelper

  describe "#update" do
    let(:shipping_method) { create(:shipping_method) }
    let(:params) {
      {
        id: shipping_method.id,
        shipping_method: {
          calculator_attributes: {
            id: shipping_method.calculator.id
          }
        }
      }
    }

    before { controller_login_as_admin }

    it "updates preferred_amount and preferred_currency of a FlatRate calculator" do
      shipping_method.calculator = create(:calculator_flat_rate, calculable: shipping_method)
      params[:shipping_method][:calculator_attributes][:preferred_amount] = 123
      params[:shipping_method][:calculator_attributes][:preferred_currency] = "EUR"

      spree_post :update, params

      expect(shipping_method.reload.calculator.preferred_amount).to eq 123
      expect(shipping_method.reload.calculator.preferred_currency).to eq "EUR"
    end

    it "updates preferred_per_kg of a Weight calculator" do
      shipping_method.calculator = create(:weight_calculator, calculable: shipping_method)
      params[:shipping_method][:calculator_attributes][:preferred_per_kg] = 10

      spree_post :update, params

      expect(shipping_method.reload.calculator.preferred_per_kg).to eq 10
    end

    it "updates preferred_flat_percent of a FlatPercentPerItem calculator" do
      shipping_method.calculator = Calculator::FlatPercentPerItem.new(preferred_flat_percent: 20,

                                                                      calculable: shipping_method)
      params[:shipping_method][:calculator_attributes][:preferred_flat_percent] = 30

      spree_post :update, params

      expect(shipping_method.reload.calculator.preferred_flat_percent).to eq 30
    end

    it "updates details of a FlexiRate calculator" do
      shipping_method.calculator = Calculator::FlexiRate.new(calculable: shipping_method)
      params[:shipping_method][:calculator_attributes][:preferred_first_item] = 10
      params[:shipping_method][:calculator_attributes][:preferred_additional_item] = 20
      params[:shipping_method][:calculator_attributes][:preferred_max_items] = 30

      spree_post :update, params

      expect(shipping_method.reload.calculator.preferred_first_item).to eq 10
      expect(shipping_method.reload.calculator.preferred_additional_item).to eq 20
      expect(shipping_method.reload.calculator.preferred_max_items).to eq 30
    end

    it "updates details of a PriceSack calculator" do
      shipping_method.calculator = Calculator::PriceSack.new(calculable: shipping_method)
      params[:shipping_method][:calculator_attributes][:preferred_minimal_amount] = 10
      params[:shipping_method][:calculator_attributes][:preferred_normal_amount] = 20
      params[:shipping_method][:calculator_attributes][:preferred_discount_amount] = 30

      spree_post :update, params

      expect(shipping_method.reload.calculator.preferred_minimal_amount).to eq 10
      expect(shipping_method.reload.calculator.preferred_normal_amount).to eq 20
      expect(shipping_method.reload.calculator.preferred_discount_amount).to eq 30
    end
  end

  describe "#delete" do
    describe "shipping method not referenced by order" do
      let(:shipping_method) { create(:shipping_method) }

      scenario "is soft deleted" do
        controller_login_as_admin
        expect(shipping_method.deleted_at).to be_nil

        spree_delete :destroy, "id" => shipping_method.id

        expect(shipping_method.reload.deleted_at).not_to be_nil
      end
    end

    describe "shipping method referenced by order" do
      let(:order) { create(:order_with_line_items) }

      scenario "is not soft deleted" do
        controller_login_as_admin
        expect(order.shipping_method.deleted_at).to be_nil

        spree_delete :destroy, "id" => order.shipping_method.id

        expect(order.shipping_method.reload.deleted_at).to be_nil
      end
    end
  end
end
