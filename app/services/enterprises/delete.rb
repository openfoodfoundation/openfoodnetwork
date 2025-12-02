# frozen_string_literal: true

module Enterprises
  class Delete
    class DeletionError < StandardError; end

    BLOCKING_ORDER_STATES = %w[complete canceled confirmation delivery payment]

    attr_reader :enterprise

    def initialize(enterprise:)
      @enterprise = enterprise
    end

    def call
      ActiveRecord::Base.transaction do
        delete_variants_for(enterprise)
        delete_variant_overrides_for(enterprise)
        delete_orders_for(enterprise)
        delete_order_cycles_for(enterprise)
        delete_preferences_for(enterprise)
        delete_enterprise_related_data_for(enterprise)

        enterprise.reload.destroy!
      end
    rescue DeletionError => e
      Rails.logger.debug { "DeletionError for Enterprise #{enterprise.id}: #{e.message}" }
    end

    private

    def delete_variants_for(enterprise)
      variants = enterprise.supplied_variants.with_deleted

      related_product_ids = variants.pluck(:product_id)

      # TODO: Handle related orders
      variants.joins(:line_items).pluck('spree_line_items.order_id')

      variants.find_each do |variant|
        check_condition_for_variant(variant)

        delete_variants_related_data_for(variant)
      end

      # As it is possible to have deleted products not related to any variant, but still linked
      # to an enterprise, we need to do this cleanup manually.
      remaining_product_ids =
        Spree::Product.with_deleted.where(supplier_id: enterprise.id).pluck(:id)

      delete_related_product(related_product_ids + remaining_product_ids)
    end

    def check_condition_for_variant(variant)
      condition =
        variant.line_items.joins(:order).where(spree_orders: { state: BLOCKING_ORDER_STATES })

      return unless condition.exists?

      raise DeletionError, "Completed Orders on Variant Found (variant id: #{variant.id})"
    end

    def delete_variants_related_data_for(variant)
      variant.stock_items.with_deleted.find_each do |stock_item|
        delete_stock_movements_for(stock_item)

        stock_item.really_destroy!
      end

      # VariantOverride has a default scope which is breaking the deletion dependency.
      # Better to clean the table manually.
      variant.variant_overrides.unscoped.find_each(&:destroy)

      variant.line_items.each(&:destroy)

      variant.really_destroy!
    end

    def delete_stock_movements_for(stock_item)
      # The table is present for history reasons. but there is no Ruby logic to call it.
      # We need to purge it manually to avoid PG constraint issues.
      sql = "DELETE FROM spree_stock_movements WHERE stock_item_id = ?"
      ActiveRecord::Base.connection.exec_delete(
        ActiveRecord::Base.sanitize_sql_array([sql, stock_item.id])
      )
    end

    def delete_related_product(product_ids)
      Spree::Product.with_deleted.where(id: product_ids).find_each do |product|
        check_condition_for_product(product)

        product.really_destroy!
      end
    end

    def check_condition_for_product(product)
      # For now, let's just really delete if the product is not linked to any variants,
      # which means that the product was just linked to previously-deleted variants
      # from the current enterprise. 90% of our cases.
      return unless product.variants.with_deleted.exists?

      raise DeletionError, "Product with External Variant Found (product id: #{product.id})"
    end

    def delete_variant_overrides_for(enterprise)
      # We delete the variant override only if no completed orders are linked to it.
      VariantOverride
        .unscoped
        .joins(:variant)
        .where(hub_id: enterprise.id)
        .find_each do |variant_override|
        check_condition_for_variant(variant_override.variant)

        variant_override.destroy!
      end
    end

    def delete_orders_for(enterprise)
      check_condition_for_enterprise(enterprise)

      # We can delete them as we checked earlier that none of them were completed
      enterprise.distributed_orders.each(&:destroy)
    end

    def check_condition_for_enterprise(enterprise)
      condition =
        enterprise.distributed_orders.where(spree_orders: { state: BLOCKING_ORDER_STATES })

      return unless condition.exists?

      raise DeletionError, "Completed Orders on Enterprise Found (enterprise id: #{enterprise.id})"
    end

    def delete_order_cycles_for(enterprise)
      # Cleaning these data, assuming that no completed orders were found earlier on variants.
      # Direct relation from enterprise to order cycle was not found
      OrderCycle.where(coordinator_id: enterprise.id).find_each do |order_cycle|
        check_condition_for_order_cycle(order_cycle)

        order_cycle.orders.unscoped.find_each(&:destroy)

        order_cycle.destroy!
      end

      Exchange.where(sender_id: enterprise.id).find_each(&:destroy!)
      Exchange.where(receiver_id: enterprise.id).find_each(&:destroy!)
    end

    def check_condition_for_order_cycle(order_cycle)
      condition =
        order_cycle.orders.where(spree_orders: { state: BLOCKING_ORDER_STATES })

      return unless condition.exists?

      raise DeletionError, "Completed Orders on OderCycle Found (order_cycle id: #{order_cycle.id})"
    end

    def delete_preferences_for(enterprise)
      Spree::Preference.where("key LIKE '%/#{enterprise.id}'").delete_all
    end

    def delete_enterprise_related_data_for(enterprise)
      # As we could force deletion when no orders were found
      ids = enterprise.distributor_shipping_methods.pluck(:id)
      DistributorShippingMethod.where(id: ids).delete_all
      ids = enterprise.distributor_payment_methods.pluck(:id)
      DistributorPaymentMethod.where(id: ids).delete_all
      # Getting cache issues on the relation locally, needed to reload it
      enterprise.enterprise_roles.delete_all
      enterprise.connected_apps.delete_all

      enterprise.enterprise_fees.with_deleted.delete_all
    end
  end
end
