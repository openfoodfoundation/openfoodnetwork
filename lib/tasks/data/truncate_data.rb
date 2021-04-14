# frozen_string_literal: true

class TruncateData
  def initialize(months_to_keep = nil)
    @date = (months_to_keep || 24).to_i.months.ago
  end

  def call
    logging do
      truncate_inventory
      truncate_adjustments
      truncate_order_associations
      truncate_order_cycle_data

      sql_delete_from "spree_orders #{where_oc_id_in_ocs_to_delete}"

      truncate_subscriptions

      sql_delete_from "order_cycles #{where_ocs_to_delete}"

      Spree::TokenizedPermission.where("created_at < '#{date}'").delete_all
    end
  end

  private

  attr_reader :date

  def logging
    Rails.logger.info("TruncateData started with truncation date #{date}")
    yield
    Rails.logger.info("TruncateData finished")
  end

  def truncate_order_associations
    sql_delete_from "spree_line_items #{where_order_id_in_orders_to_delete}"
    sql_delete_from "spree_payments #{where_order_id_in_orders_to_delete}"
    sql_delete_from "spree_shipments #{where_order_id_in_orders_to_delete}"
    sql_delete_from "spree_return_authorizations #{where_order_id_in_orders_to_delete}"
  end

  def truncate_subscriptions
    sql_delete_from "order_cycle_schedules #{where_oc_id_in_ocs_to_delete}"
    sql_delete_from "proxy_orders #{where_oc_id_in_ocs_to_delete}"
  end

  def truncate_inventory
    sql_delete_from "
        spree_inventory_units #{where_order_id_in_orders_to_delete}"
    sql_delete_from "
        spree_inventory_units
        where shipment_id in (select id from spree_shipments #{where_order_id_in_orders_to_delete})"
  end

  def sql_delete_from(sql)
    ActiveRecord::Base.connection.execute("DELETE FROM #{sql}")
  end

  def where_order_id_in_orders_to_delete
    "where order_id in (select id from spree_orders #{where_oc_id_in_ocs_to_delete})"
  end

  def where_oc_id_in_ocs_to_delete
    "where order_cycle_id in (select id from order_cycles #{where_ocs_to_delete} )"
  end

  def where_ocs_to_delete
    "where orders_close_at < '#{date}'"
  end

  def truncate_adjustments
    sql_delete_from "spree_adjustments where adjustable_type = 'Spree::Order'
      and adjustable_id in (select id from spree_orders #{where_oc_id_in_ocs_to_delete})"

    sql_delete_from "spree_adjustments where adjustable_type = 'Spree::Shipment'
      and adjustable_id in (select id from spree_shipments #{where_order_id_in_orders_to_delete})"

    sql_delete_from "spree_adjustments where adjustable_type = 'Spree::Payment'
      and adjustable_id in (select id from spree_payments #{where_order_id_in_orders_to_delete})"

    sql_delete_from "spree_adjustments where adjustable_type = 'Spree::LineItem'
      and adjustable_id in (select id from spree_line_items #{where_order_id_in_orders_to_delete})"
  end

  def truncate_order_cycle_data
    sql_delete_from "coordinator_fees #{where_oc_id_in_ocs_to_delete}"
    sql_delete_from "
    exchange_variants where exchange_id
    in (select id from exchanges #{where_oc_id_in_ocs_to_delete})"
    sql_delete_from "
        exchange_fees where exchange_id
        in (select id from exchanges #{where_oc_id_in_ocs_to_delete})"
    sql_delete_from "exchanges #{where_oc_id_in_ocs_to_delete}"
  end
end
