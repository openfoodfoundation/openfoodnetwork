# frozen_string_literal: true

module DfcProvider
  class AnonymousOrdersController < DfcProvider::ApplicationController
    def index
      orders = anonymous_orders.map do |order|
        OrderBuilder.build_anonymous(order)
      end
      render json: DfcIo.export(*orders)
    end

    private

    def anonymous_orders
      Spree::LineItem
        .joins(Arel.sql(joins_conditions))
        .select(Arel.sql(select_fields))
        .where(where_conditions)
        .group(Arel.sql(group_fields))
        .order(Arel.sql(order_fields))
    end

    def joins_conditions
      [
        "JOIN spree_orders ON spree_orders.id = spree_line_items.order_id",
        "JOIN spree_variants ON spree_variants.id = spree_line_items.variant_id",
        "JOIN spree_products ON spree_products.id = spree_variants.product_id",
        "JOIN enterprises AS enterprise1 ON spree_orders.distributor_id = enterprise1.id",
        "JOIN enterprises AS enterprise2 ON spree_products.supplier_id = enterprise2.id",
        "JOIN spree_addresses AS distributors ON enterprise1.address_id = distributors.id",
        "JOIN spree_addresses AS producers ON enterprise2.address_id = producers.id"
      ].join(' ')
    end

    def select_fields
      "spree_products.name AS product_name,
       spree_variants.display_name AS unit_name,
       spree_products.variant_unit AS unit_type,
       spree_variants.unit_value AS units,
       spree_variants.unit_presentation,
       SUM(spree_line_items.quantity) AS quantity_sold,
       spree_line_items.price,
       distributors.zipcode AS distributor_postcode,
       producers.zipcode AS producer_postcode"
    end

    def where_conditions
      { spree_orders: { state: 'complete' } }
    end

    def group_fields
      'spree_products.name,
       spree_variants.display_name,
       spree_variants.unit_value,
       spree_variants.unit_presentation,
       spree_products.variant_unit,
       spree_line_items.price,
       distributors.zipcode,
       producers.zipcode'
    end

    def order_fields
      'spree_products.name'
    end
  end
end
