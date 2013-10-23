Spree::StoreController.class_eval do
  include OrderCyclesHelper
  before_filter :check_order_cycle_expiry
end
