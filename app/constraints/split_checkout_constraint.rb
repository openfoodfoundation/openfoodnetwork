class SplitCheckoutConstraint
  def matches?(request)
    Flipper.enabled? :split_checkout, current_user(request)
  end

  def current_user(request)
    @spree_current_user ||= request.env['warden'].user
  end
end
