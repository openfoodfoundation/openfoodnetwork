class ActivateSplitCheckoutByDefault < ActiveRecord::Migration[7.0]
  def change
    Flipper.enable(:split_checkout)
  end
end
