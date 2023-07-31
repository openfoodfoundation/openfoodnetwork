# frozen_string_literal: true

# Locks a controller's current order including its variants.
#
# It should be used when making major changes like checking out the order.
# It can keep stock checking in sync and prevent overselling of an item.
class CurrentOrderLocker
  # This interface follows the ActionController filters convention:
  #
  #   https://guides.rubyonrails.org/action_controller_overview.html#filters
  #
  def self.around(controller, &)
    lock_order_and_variants(controller.current_order, &)
  end

  # Locking will not prevent all access to these rows. Other processes are
  # only waiting if they try to lock one of these rows as well.
  #
  #   https://api.rubyonrails.org/classes/ActiveRecord/Locking/Pessimistic.html
  #
  def self.lock_order_and_variants(order)
    return yield if order.nil?

    order.with_lock do
      lock_variants_of(order)
      yield
    end
  end
  private_class_method :lock_order_and_variants

  # There are many places in which stock is stored in the database. Row locking
  # on variant level ensures that there are no conflicts even when an item is
  # sold through multiple shops.
  def self.lock_variants_of(order)
    variant_ids = order.line_items.select(:variant_id)

    # Ordering the variants by id prevents deadlocks. Plucking the ids sends
    # the locking query without building Spree::Variant objects.
    Spree::Variant.where(id: variant_ids).order(:id).lock.pluck(:id)
  end
  private_class_method :lock_variants_of
end
