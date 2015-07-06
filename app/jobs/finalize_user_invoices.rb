FinalizeUserInvoices = Struct.new("FinalizeUserInvoices") do

  def perform
    return unless accounts_distributor = Enterprise.find_by_id(Spree::Config.accounts_distributor_id)
    return unless accounts_distributor.payment_methods.find_by_id(Spree::Config.default_accounts_payment_method_id)
    return unless accounts_distributor.shipping_methods.find_by_id(Spree::Config.default_accounts_shipping_method_id)

    start_date = (Time.now.beginning_of_month - 1.month) + 1.day
    end_date = Time.now.beginning_of_month + 1.day

    invoices = Spree::Order.where('distributor_id = (?) AND created_at >= (?) AND created_at <= (?) AND completed_at IS NULL',
      accounts_distributor, start_date, end_date)

    invoices.each do |invoice|
      finalize(invoice)
    end
  end

  def finalize(invoice)
    # TODO: When we implement per-customer and/or per-user preferences around shipping and payment methods
    # we can update these to read from those preferences
    invoice.payments.create(payment_method_id: Spree::Config.default_accounts_payment_method_id, amount: invoice.total)
    invoice.update_attribute(:shipping_method_id, Spree::Config.default_accounts_shipping_method_id)

    while invoice.state != "complete"
      invoice.next
    end
  end
end
