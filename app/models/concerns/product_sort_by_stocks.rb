# frozen_string_literal: true

module ProductSortByStocks
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    @on_hand_sql = Arel.sql("(
      SELECT COALESCE(SUM(si.count_on_hand), 0)
      FROM spree_variants v
      JOIN spree_stock_items si ON si.variant_id = v.id
      WHERE v.product_id = spree_products.id
      GROUP BY v.product_id
    )")

    @backorderable_priority_sql = Arel.sql("(
      SELECT BOOL_OR(si.backorderable)
      FROM spree_variants v
      JOIN spree_stock_items si ON si.variant_id = v.id
      WHERE v.product_id = spree_products.id
      GROUP BY v.product_id
    )")

    # When a product is On-Demand (backorderable = true), return the product name.
    # This allows alphabetical ordering inside the On-Demand group.
    # For non-On-Demand products, return NULL so normal on_hand sorting still applies.
    @backorderable_name_sql = Arel.sql("
      CASE
        WHEN (#{@backorderable_priority_sql}) THEN spree_products.name
        ELSE NULL
      END
    ")

    class << self
      attr_reader :on_hand_sql, :backorderable_priority_sql, :backorderable_name_sql
    end

    ransacker :on_hand do
      @on_hand_sql
    end

    ransacker :backorderable_priority do
      @backorderable_priority_sql
    end

    ransacker :backorderable_name do
      @backorderable_name_sql
    end
  end
end
