# frozen_string_literal: true

require 'order_management/subscriptions/proxy_order_syncer'

class OrderCycleClone
  def initialize(order_cycle)
    @original_order_cycle = order_cycle
  end

  def create
    oc = @original_order_cycle.dup
    oc.name = I18n.t("models.order_cycle.cloned_order_cycle_name", order_cycle: oc.name)
    oc.orders_open_at = oc.orders_close_at = oc.mails_sent = oc.processed_at = nil
    oc.coordinator_fee_ids = @original_order_cycle.coordinator_fee_ids
    oc.preferred_product_selection_from_coordinator_inventory_only =
      @original_order_cycle.preferred_product_selection_from_coordinator_inventory_only
    oc.schedule_ids = @original_order_cycle.schedule_ids
    oc.save!
    @original_order_cycle.exchanges.each { |e| e.clone!(oc) }
    oc.selected_distributor_payment_method_ids = selected_distributor_payment_method_ids
    oc.selected_distributor_shipping_method_ids = selected_distributor_shipping_method_ids
    sync_subscriptions
    oc.reload
  end

  private

  def selected_distributor_payment_method_ids
    @original_order_cycle.attachable_distributor_payment_methods.map(&:id) &
      @original_order_cycle.selected_distributor_payment_method_ids
  end

  def selected_distributor_shipping_method_ids
    @original_order_cycle.attachable_distributor_shipping_methods.map(&:id) &
      @original_order_cycle.selected_distributor_shipping_method_ids
  end

  def sync_subscriptions
    return unless @original_order_cycle.schedule_ids.any?

    OrderManagement::Subscriptions::ProxyOrderSyncer.new(
      Subscription.where(schedule_id: @original_order_cycle.schedule_ids)
    ).sync!
  end
end
