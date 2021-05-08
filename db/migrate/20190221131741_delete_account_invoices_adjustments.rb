class DeleteAccountInvoicesAdjustments < ActiveRecord::Migration[4.2]
  def up
    Spree::Adjustment
      .where(source_type: 'BillablePeriod')
      .destroy_all
  end

  def down
    # This data does not need to be recovered
  end
end
