# frozen_string_literal: true

module Enterprises
  class Delete
    attr_reader :enterprise
    attr_accessor :skip_real_deletion

    def initialize(enterprise:)
      @enterprise = enterprise
    end

    def call
      self.skip_real_deletion = false

      ActiveRecord::Base.transaction do
        variants = enterprise.supplied_variants.with_deleted

        # TODO: Deal with related products after the variants
        related_product_ids = variants.pluck(:product_id)

        # TODO: Handle related orders
        variants.joins(:line_items).pluck('spree_line_items.order_id')

        puts "==== Variants count before: #{variants.count}"
        variants.find_each do |variant|
          if skipping_condition_for(variant)
            self.skip_real_deletion = true
            next
          end

          delete_variants_related_data_for(variant)
        end
        puts "==== Variants count after: #{enterprise.reload.supplied_variants.with_deleted.count}"

        delete_related_product(related_product_ids)

        if skip_real_deletion
          puts '===== Real deletion impossible...'
        else
          # As we could force deletion when no orders were found
          ids = enterprise.distributor_shipping_methods.pluck(:id)
          DistributorShippingMethod.where(id: ids).delete_all
          ids = enterprise.distributor_payment_methods.pluck(:id)
          DistributorPaymentMethod.where(id: ids).delete_all

          # As the relation seems broken...
          EnterpriseRole.where(enterprise_id: enterprise.id).delete_all

          enterprise.destroy!
        end
      end
    end

    private

    def delete_stock_movements_for(stock_item)
      # The table is present for history reasons. but there is no Ruby logic to call it.
      # We need to purge it manually to avoid PG constraint issues.
      sql = "DELETE FROM spree_stock_movements WHERE stock_item_id = ?"
      ActiveRecord::Base.connection.exec_delete(
        ActiveRecord::Base.sanitize_sql_array([sql, stock_item.id])
      )
    end

    def delete_variants_related_data_for(variant)
      variant.stock_items.with_deleted.find_each do |stock_item|
        delete_stock_movements_for(stock_item)

        stock_item.really_destroy!
      end

      variant.line_items.each(&:destroy)

      variant.really_destroy!
    end

    def delete_related_product(product_ids)
      Spree::Product.where(id: product_ids).includes(:variants).find_each do |product|
        # For now, let's just really delete if the product is not linked to any variants,
        # which means that the product was just linked to deletable variants from the
        # current enterprise. 90% of our cases.
        if product.variants.exists?
          self.skip_real_deletion = true
        else
          product.really_destroy!
        end
      end
    end

    def skipping_condition_for(variant)
      orders_per_state_count = variant.line_items.joins(:order).group('spree_orders.state').count
      puts "== Related orders: #{orders_per_state_count}"

      # For now, we decide that we cannot delete an enterprise if there is a completed order
      # linked to it.
      orders_per_state_count['complete'].to_i > 0
    end
  end
end
