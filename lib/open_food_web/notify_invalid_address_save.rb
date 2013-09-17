module OpenFoodWeb

  # We have a hard-to-track-down bug around invalid addresses with all-nil fields finding
  # their way into the database. I don't know what the source of them is, so this patch
  # is designed to track them down.
  # This is intended to be a temporary investigative measure, and should be removed from the
  # code base shortly.
  #
  #-- Rohan, 17-9-2913
  module NotifyInvalidAddressSave
    def create
      if self.class == Spree::Address && self.zipcode.nil?
        Bugsnag.notify RuntimeError.new('Saving a Spree::Address with nil values')
      end

      super
    end

    def update
      if self.class == Spree::Address && self.zipcode.nil?
        Bugsnag.notify RuntimeError.new('Saving a Spree::Address with nil values')
      end

      super
    end
  end
end


module ActiveRecord
  class Base
    include OpenFoodWeb::NotifyInvalidAddressSave
  end
end
