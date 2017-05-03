Spree::UsersController.class_eval do
  layout 'darkswarm'

  before_filter :enable_embedded_shopfront
end
