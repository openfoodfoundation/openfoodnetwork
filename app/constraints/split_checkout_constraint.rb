# frozen_string_literal: true

class SplitCheckoutConstraint
  def matches?(request)
    Flipper.enabled? :split_checkout, current_user(request)
  end

  def current_user(request)
    request.env['warden'].user
  end
end
