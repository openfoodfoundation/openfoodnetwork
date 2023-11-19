class ActivateVoucherByDefault < ActiveRecord::Migration[7.0]
  def up
    Flipper.enable(:vouchers)
  end
end
