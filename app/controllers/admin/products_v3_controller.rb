# frozen_string_literal: true

module Admin
  class ProductsV3Controller < Spree::Admin::BaseController
    before_action :fetch_products

    def index; end

    def fetch_products
      # product_query = OpenFoodNetwork::Permissions.new(spree_current_user).editable_products.merge(product_scope)
      product_query = Spree::Product.limit(10)
      @products = product_query
    end

    def product_scope
      scope = if spree_current_user.has_spree_role?("admin") || spree_current_user.enterprises.present?
                Spree::Product
              else
                Spree::Product.active
              end
    end
  end
end
