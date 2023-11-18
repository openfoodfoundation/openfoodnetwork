class ActivateVoucherByDefault < ActiveRecord::Migration[7.0]
  def change
    Flipper.enable(:vouchers)
  end
end
