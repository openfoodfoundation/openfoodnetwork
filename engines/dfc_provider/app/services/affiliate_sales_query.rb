# frozen_string_literal: true

class AffiliateSalesQuery
  class << self
    def data(enterprises)
      Spree::LineItem
        .joins(tables)
        .where(
          spree_orders: { state: "complete", distributor_id: enterprises },
        )
        .group(key_fields)
        .pluck(fields)
    end

    # Create a hash with labels for an array of data points:
    #
    #   { product_name: "Apple", ... }
    def label_row(row)
      labels.zip(row).to_h
    end

    private

    # We want to collect a lot of data from only a few columns.
    # It's more efficient with `pluck`. But therefore we need well named
    # tables and columns, especially because we are going to join some tables
    # twice for different columns. For example the distributer postcode and
    # the supplier postcode. That's why we need SQL here instead of nice Rails
    # associations.
    def tables
      <<~SQL.squish
        JOIN spree_variants ON spree_variants.id = spree_line_items.variant_id
        JOIN spree_products ON spree_products.id = spree_variants.product_id
        JOIN enterprises AS suppliers ON suppliers.id = spree_variants.supplier_id
        JOIN spree_addresses AS supplier_addresses ON supplier_addresses.id = suppliers.address_id
        JOIN spree_orders ON spree_orders.id = spree_line_items.order_id
        JOIN enterprises AS distributors ON distributors.id = spree_orders.distributor_id
        JOIN spree_addresses AS distributor_addresses ON distributor_addresses.id = distributors.address_id
      SQL
    end

    def fields
      <<~SQL.squish
        spree_products.name AS product_name,
        spree_variants.display_name AS unit_name,
        spree_products.variant_unit AS unit_type,
        spree_variants.unit_value AS units,
        spree_variants.unit_presentation,
        spree_line_items.price,
        distributor_addresses.zipcode AS distributor_postcode,
        supplier_addresses.zipcode AS supplier_postcode,

        SUM(spree_line_items.quantity) AS quantity_sold
      SQL
    end

    def key_fields
      <<~SQL.squish
        product_name,
        unit_name,
        unit_type,
        units,
        spree_variants.unit_presentation,
        spree_line_items.price,
        distributor_postcode,
        supplier_postcode
      SQL
    end

    # A list of column names as symbols to be used as hash keys.
    def labels
      %i[
        product_name
        unit_name
        unit_type
        units
        unit_presentation
        price
        distributor_postcode
        supplier_postcode
        quantity_sold
      ]
    end
  end
end
