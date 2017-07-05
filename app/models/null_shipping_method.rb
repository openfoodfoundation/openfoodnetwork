# Represents an empty shipping method, useful when the user didn't choose
# any but we still need to display it in the UI.
class NullShippingMethod
  def name
    nil
  end

  def require_ship_address
    nil
  end
end
