# This task can be used to significantly reduce the size of a database
#   This is used for example when loading live data into a staging server
#   This way the staging server is not overloaded with too much data
namespace :ofn do
  namespace :data do
    desc 'Truncate data'
    task truncate: :environment do
      guard_and_warn

      sql_delete_from "
        spree_inventory_units #{where_order_id_in_orders_to_delete}"

      truncate_adjustments

      sql_delete_from "spree_line_items #{where_order_id_in_orders_to_delete}"
      sql_delete_from "spree_payments #{where_order_id_in_orders_to_delete}"
      sql_delete_from "spree_shipments #{where_order_id_in_orders_to_delete}"
      Spree::ReturnAuthorization.delete_all

      truncate_order_cycle_data

      sql_delete_from "proxy_orders #{where_oc_id_in_ocs_to_delete}"

      sql_delete_from "spree_orders #{where_oc_id_in_ocs_to_delete}"
      sql_delete_from "order_cycle_schedules #{where_oc_id_in_ocs_to_delete}"
      sql_delete_from "order_cycles #{where_ocs_to_delete}"

      Spree::TokenizedPermission.where("created_at < '#{date}'").delete_all
      Spree::StateChange.delete_all
      Spree::LogEntry.delete_all
      sql_delete_from "sessions"
    end

    def sql_delete_from(sql)
      ActiveRecord::Base.connection.execute("delete from #{sql}")
    end

    private

    def date
      3.months.ago
    end

    def where_ocs_to_delete
      "where orders_close_at < '#{date}'"
    end

    def where_oc_id_in_ocs_to_delete
      "where order_cycle_id in (select id from order_cycles #{where_ocs_to_delete} )"
    end

    def where_order_id_in_orders_to_delete
      "where order_id in (select id from spree_orders #{where_oc_id_in_ocs_to_delete})"
    end

    def truncate_adjustments
      sql_delete_from "spree_adjustments where source_type = 'Spree::Order'
        and source_id in (select id from spree_orders #{where_oc_id_in_ocs_to_delete})"
      sql_delete_from "spree_adjustments where source_type = 'Spree::Shipment'
        and source_id in (select id from spree_shipments #{where_order_id_in_orders_to_delete})"
      sql_delete_from "spree_adjustments where source_type = 'Spree::Payment'
        and source_id in (select id from spree_payments #{where_order_id_in_orders_to_delete})"
      sql_delete_from "spree_adjustments where source_type = 'Spree::LineItem'
        and source_id in (select id from spree_line_items #{where_order_id_in_orders_to_delete})"
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
end
