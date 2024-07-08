# frozen_string_literal: true

class AffiliateSalesQuery
  class << self
    def call
      Spree::LineItem
        .joins(sales_data_joins)
        .select(sales_data_select)
        .where({ spree_orders: { state: 'complete' } })
        .group(sales_data_group)
        .order('spree_products.name')
    end

    private

    def sales_data_joins
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

    def sales_data_select
      <<~SQL.squish
        spree_orders.id AS order_id,
        spree_orders.created_at AS order_date,
        spree_products.id AS product_id,
        spree_products.name AS product_name,
        spree_variants.display_name AS unit_name,
        spree_products.variant_unit AS unit_type,
        spree_variants.unit_value AS units,
        spree_variants.unit_presentation,
        spree_line_items.quantity AS line_item_quantity,
        SUM(spree_line_items.quantity) AS quantity_sold,
        spree_line_items.id AS line_item_id,
        spree_line_items.price,
        spree_line_items.currency,
        producers.id AS producer_id,
        distributors.id AS distributor_id,
        distributors.zipcode AS distributor_postcode,
        producers.zipcode AS producer_postcode
      SQL
    end

    def sales_data_group
      <<~SQL.squish
        spree_orders.id,
        spree_products.id,
        spree_products.name,
        spree_variants.display_name,
        spree_variants.unit_value,
        spree_variants.unit_presentation,
        spree_products.variant_unit,
        spree_line_items.id,
        spree_line_items.price,
        producers.id,
        distributors.id,
        distributors.zipcode,
        producers.zipcode
      SQL
    end
  end
end
