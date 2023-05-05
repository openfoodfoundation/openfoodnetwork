# frozen_string_literal: true

require 'open_food_network/permissions'

module Permissions
  class Order
    def initialize(user, search_params = nil)
      @user = user
      @permissions = OpenFoodNetwork::Permissions.new(@user)
      @search_params = search_params
    end

    # Find orders that the user can see. This includes any order where the producer has permissions
    # and has at least *one* of their supplied products in the order. Additional scoping may be
    # needed for queries showing line items per producer.
    def visible_orders
      orders = Spree::Order.
        with_line_items_variants_and_products_outer.
        where(visible_orders_where_values)

      filtered_orders(orders)
    end

    # Any orders that the user can edit
    def editable_orders
      orders = Spree::Order.
        where(managed_orders_where_values.
          or(coordinated_orders_where_values))

      filtered_orders(orders)
    end

    def visible_line_items
      editable_line_items.or(produced_line_items)
    end

    # Any line items that I can edit
    def editable_line_items
      Spree::LineItem.where(order_id: editable_orders.select(:id))
    end

    private

    attr_reader :search_params

    def filtered_orders(orders)
      return orders unless filter_orders?

      orders.complete.not_state(:canceled).ransack(search_params).result
    end

    def filter_orders?
      search_params.present?
    end

    def visible_orders_where_values
      # Grouping keeps the 2 where clauses from produced_orders_where_values inside parentheses
      #   This way it makes the OR work between the 3 types of orders:
      #     produced, managed and coordinated
      Spree::Order.arel_table.
        grouping(produced_orders_where_values).
        or(managed_orders_where_values).
        or(coordinated_orders_where_values)
    end

    # Any orders placed through any hub that I manage
    def managed_orders_where_values
      Spree::Order.
        where(distributor_id: @permissions.managed_enterprises.select("enterprises.id")).
        where_clause.__send__(:predicates).
        reduce(:and)
    end

    # Any order that is placed through an order cycle one of my managed enterprises coordinates
    def coordinated_orders_where_values
      Spree::Order.
        where(order_cycle_id: @permissions.coordinated_order_cycles.select(:id)).
        where_clause.__send__(:predicates).
        reduce(:and)
    end

    def produced_orders_where_values
      Spree::Order.with_line_items_variants_and_products_outer.
        where(
          distributor_id: granted_distributor_ids,
          spree_products: { supplier_id: enterprises_with_associated_orders }
        ).
        where_clause.__send__(:predicates).
        reduce(:and)
    end

    def enterprises_with_associated_orders
      # Any orders placed through hubs that my producers have granted P-OC,
      #   and which contain their products. This is pretty complicated but it's looking for order
      #   where at least one of my producers has granted P-OC to the distributor
      #   AND the order contains products of at least one of THE SAME producers
      @permissions.related_enterprises_granting(:add_to_order_cycle, to: granted_distributor_ids).
        merge(@permissions.managed_enterprises.is_primary_producer)
    end

    def granted_distributor_ids
      @granted_distributor_ids ||= @permissions.related_enterprises_granted(
        :add_to_order_cycle,
        by: @permissions.managed_enterprises.is_primary_producer.select("enterprises.id")
      ).select("enterprises.id")
    end

    # Any from visible orders, where the product is produced by one of my managed producers
    def produced_line_items
      Spree::LineItem.where(order_id: visible_orders.select("DISTINCT spree_orders.id")).
        supplied_by_any(
          @permissions.managed_enterprises.is_primary_producer.select("enterprises.id")
        )
    end
  end
end
