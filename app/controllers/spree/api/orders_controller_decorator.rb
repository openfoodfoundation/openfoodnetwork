Spree::Api::OrdersController.class_eval do

  # We need to add expections for collection actions other than :index here
  # because Spree's API controller causes authorize_read! to be called, which
  # results in an ActiveRecord::NotFound Exception as the order object is not
  # defined for collection actions
end
