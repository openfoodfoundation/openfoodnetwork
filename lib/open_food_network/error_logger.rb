# frozen_string_literal: true

# Our error logging API currently wraps Bugsnag.
# It makes us more flexible if we wanted to replace Bugsnag or change logging
# behaviour.
module OpenFoodNetwork
  module ErrorLogger
    # Tries to escalate the error to a developer.
    # If Bugsnag is configured, it will notify it. It would be nice to implement
    # some kind of fallback.
    def self.notify(error)
      Bugsnag.notify(error)
    end
  end
end
