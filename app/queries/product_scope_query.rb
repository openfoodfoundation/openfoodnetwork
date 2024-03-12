# frozen_string_literal: true

class ProductScopeQuery
  def initialize(user, params)
    @user = user
    @params = params
  end

  def bulk_products
    product_query = OpenFoodNetwork::Permissions.
      new(@user).
      editable_products.
      merge(product_scope)

    if @params[:import_date].present?
      product_query = product_query.
        imported_on(@params[:import_date]).
        group_by_products_id
    end

    product_query.
      ransack(query_params_with_defaults).
      result(distinct: true)
  end

  def find_product
    product_scope.find(@params[:id])
  end

  def find_product_to_be_cloned
    product_scope.find(@params[:product_id])
  end

  def paged_products_for_producers
    producer_ids = OpenFoodNetwork::Permissions.new(@user).
      variant_override_producers.by_name.select('enterprises.id')

    Spree::Product.where(nil).
      merge(product_scope).
      includes(variants: [:product, :default_price, :stock_items]).
      where(supplier_id: producer_ids).
      by_producer.by_name.
      ransack(@params[:q]).result
  end

  def product_scope
    if @user.has_spree_role?("admin") || @user.enterprises.present?
      scope = Spree::Product
      if @params[:show_deleted]
        scope = scope.with_deleted
      end
    else
      scope = Spree::Product.active
    end

    scope.includes(product_query_includes)
  end

  def product_query_includes
    [
      image: { attachment_attachment: :blob },
      variants: [:default_price, :stock_locations, :stock_items, :variant_overrides]
    ]
  end

  def query_params_with_defaults
    (@params[:q] || {}).reverse_merge(s: 'created_at desc')
  end
end
