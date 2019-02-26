class DeleteAccountInvoicesAdjustments < ActiveRecord::Migration
  def up
    Spree::Adjustment
      .where(source_type: 'BillablePeriod')
      .destroy_all
  end

  def down
    # This data does not need to be recovered
  end
end
