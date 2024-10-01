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
    OrderLocker.lock_order_and_variants(controller.current_order, &)
  end
end
