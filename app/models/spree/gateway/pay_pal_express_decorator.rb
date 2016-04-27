module Spree
  class Gateway::PayPalExpress < Gateway
    # Something odd is happening with class inheritance here, this class (defined in spree_paypal_express gem)
    # doesn't seem to pick up attr_accessible from the Gateway class, so we redefine the attrs we need here
    attr_accessible :tag_list
  end
end
