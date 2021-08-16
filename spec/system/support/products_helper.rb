# frozen_string_literal: true

module OpenFoodNetwork
  module ProductsHelper
    def with_products_require_tax_category(value)
      original_value = Spree::Config.products_require_tax_category

      Spree::Config.products_require_tax_category = value
      yield
    ensure
      Spree::Config.products_require_tax_category = original_value
    end

    shared_examples "modifying product actions are restricted" do
      it "cannot create a new product if not an admin" do
        api_post :create, product: { name: "Brand new product!" }
        assert_unauthorized!
      end

      it "cannot update a product" do
        api_put :update, id: product.to_param, product: { name: "I hacked your store!" }
        assert_unauthorized!
      end

      it "cannot delete a product" do
        api_delete :destroy, id: product.to_param
        assert_unauthorized!
      end
    end
  end
end
