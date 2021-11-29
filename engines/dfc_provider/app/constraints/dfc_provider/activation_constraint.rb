# frozen_string_literal: true

module DfcProvider
  class ActivationConstraint
    def matches?(request)
      return true if Rails.env.development? || Rails.env.test?

      Flipper.enabled? :dfc_provider, current_user(request)
    end

    def current_user(request)
      @current_user ||= request.env['warden'].user
    end
  end
end
