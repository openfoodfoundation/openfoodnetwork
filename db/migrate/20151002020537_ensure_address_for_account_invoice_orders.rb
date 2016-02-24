class EnsureAddressForAccountInvoiceOrders < ActiveRecord::Migration
  def up
    AccountInvoice.where('order_id IS NOT NULL').each do |account_invoice|
      billable_periods = account_invoice.billable_periods.order(:enterprise_id).reject{ |bp| bp.turnover == 0 }

      if billable_periods.any?
        address = billable_periods.first.enterprise.address
        account_invoice.order.update_attributes(bill_address: address, ship_address: address)
      end
    end
  end

  def down
  end
end
