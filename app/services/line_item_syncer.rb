# Responsible for keeping line items on initialised orders for a subscription in sync with
# the subscription line items on that subscription.

class LineItemSyncer
  def initialize(subscription, order_update_issues)
    @subscription = subscription
    @order_update_issues = order_update_issues
  end

  def sync!(order)
    update_item_quantities(order)
    create_new_items(order)
    destroy_obsolete_items(order)
  end

  private

  delegate :subscription_line_items, to: :subscription

  attr_reader :subscription, :order_update_issues

  def update_item_quantities(order)
    changed_subscription_line_items.each do |sli|
      line_item = order.line_items.find_by_variant_id(sli.variant_id)
      next if update_quantity(line_item, sli)
      product_name = "#{line_item.product.name} - #{line_item.full_name}"
      order_update_issues.add(order, product_name)
    end
  end

  def create_new_items(order)
    new_subscription_line_items.each do |sli|
      new_line_item = order.line_items.create(variant_id: sli.variant_id, quantity: sli.quantity, skip_stock_check: skip_stock_check?(order))
      new_line_item.destroy if !skip_stock_check?(order) && new_line_item.insufficient_stock?
    end
  end

  def destroy_obsolete_items(order)
    order.line_items.where(variant_id: subscription_line_items.select(&:marked_for_destruction?).map(&:variant_id)).destroy_all
  end

  def changed_subscription_line_items
    subscription_line_items.select{ |sli| sli.changed? && sli.persisted? }
  end

  def new_subscription_line_items
    subscription_line_items.select(&:new_record?)
  end

  def update_quantity(line_item, sli)
    if line_item.quantity == sli.quantity_was
      return line_item.update_attributes(quantity: sli.quantity, skip_stock_check: skip_stock_check?(line_item.order))
    end
    line_item.quantity == sli.quantity
  end

  def skip_stock_check?(order)
    !order.complete?
  end
end
