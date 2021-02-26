# frozen_string_literal: true

# Rails 5 introduced some breaking changes to these built-in methods, and the new versions
# no longer work correctly in relation to decrementing stock with LineItems / VariantOverrides.
# The following methods re-instate the pre-Rails-5 versions, which work as expected.
# https://apidock.com/rails/v4.2.9/ActiveRecord/Persistence/increment%21
# https://apidock.com/rails/v4.2.9/ActiveRecord/Persistence/decrement%21

module LineItemStockChanges
  extend ActiveSupport::Concern

  def increment!(attribute, by = 1)
    increment(attribute, by).update_attribute(attribute, self[attribute])
  end

  def decrement!(attribute, by = 1)
    decrement(attribute, by).update_attribute(attribute, self[attribute])
  end
end
