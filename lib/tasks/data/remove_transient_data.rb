# frozen_string_literal: true

class RemoveTransientData
  RETENTION_PERIOD = 3.months

  # This model lets us operate on the sessions DB table using ActiveRecord's
  # methods within the scope of this service. This relies on the AR's
  # convention where a Session model maps to a sessions table.
  class Session < ApplicationRecord
  end

  attr_reader :expiration_date

  def initialize
    @expiration_date = RETENTION_PERIOD.ago.to_date
  end

  def call
    Rails.logger.info("#{self.class.name}: processing")

    buffer_days = 15.days

    state_change_query = Proc.new do |start_interval, end_interval|
      Spree::StateChange.
        where(created_at: start_interval..end_interval.end_of_day).
        delete_all
    end
    min_created_at = Spree::StateChange.minimum(:created_at).try(:to_date)

    batched_delete_all_over_time(state_change_query, Spree::StateChange, buffer_days, min_created_at, expiration_date)

    log_entry_query = Proc.new do |start_interval, end_interval|
      Spree::LogEntry.
        where(created_at: start_interval..end_interval.end_of_day).
        delete_all
    end
    min_created_at = Spree::LogEntry.minimum(:created_at).try(:to_date)

    batched_delete_all_over_time(log_entry_query, Spree::LogEntry, buffer_days, min_created_at, expiration_date)

    session_query = Proc.new do |start_interval, end_interval|
      Session.
        where(updated_at: start_interval..end_interval.end_of_day).
        delete_all
    end
    min_updated_at = Session.minimum(:updated_at).try(:to_date)

    batched_delete_all_over_time(session_query, Session, buffer_days, min_updated_at, expiration_date)

    clear_old_cart_data!
  end

  private

  def clear_old_cart_data!
    old_carts = Spree::Order.
      where("spree_orders.state = 'cart' AND spree_orders.updated_at < ?", expiration_date).
      merge(orders_without_payments)

    line_items_query = Proc.new do |ids|
      Spree::LineItem.where(order_id: ids).pluck(:id)
    end
    old_cart_line_items = batched_delete_all_with_ids(
      line_items_query, old_carts, Spree::LineItem
    )

    adjustments_query = Proc.new do |ids|
      Spree::Adjustment.where(order_id: ids).pluck(:id)
    end
    old_cart_adjustments = batched_delete_all_with_ids(
      adjustments_query, old_carts, Spree::Adjustment
    )

    old_cart_ids = old_carts.pluck(:id)
    old_carts_query = Proc.new do |ids|
      Spree::Order.where(id: ids).pluck(:id)
    end
    old_carts = batched_delete_all_with_ids(
      old_carts_query, old_cart_ids, Spree::Order
    )
  end

  def orders_without_payments
    # Carts with failed payments are ignored, as they contain potentially useful data
    Spree::Order.
      joins("LEFT OUTER JOIN spree_payments ON spree_orders.id = spree_payments.order_id").
      where(spree_payments: { id: nil })
  end

  def batched_delete_all_with_ids(query_proc, ids, model_class)
    ids.in_groups_of(1000, false).each do |batch|
      model_ids = query_proc.call(batch)
      model_class.where(id: model_ids).delete_all
    end
  end

  def batched_delete_all_over_time(query_proc, model_class, buffer_days, min_date, retention_period)
    end_interval = retention_period - 1.day
    start_interval = end_interval - buffer_days

    return if min_date.blank?

    while start_interval >= min_date do
      query_proc.call(start_interval.beginning_of_day, end_interval.end_of_day)

      start_interval -= buffer_days
      end_interval -= buffer_days
    end

    query_proc.call(min_date.beginning_of_day, end_interval.end_of_day)
  end
end
