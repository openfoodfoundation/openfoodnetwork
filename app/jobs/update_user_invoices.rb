UpdateUserInvoices = Struct.new("UpdateUserInvoices") do
  def perform
    return unless accounts_distributor = Enterprise.find_by_id(Spree::Config.accounts_distributor_id)
    return unless accounts_distributor.payment_methods.find_by_id(Spree::Config.default_accounts_payment_method_id)
    return unless accounts_distributor.shipping_methods.find_by_id(Spree::Config.default_accounts_shipping_method_id)

    # If it is the first of the month, update invoices for the previous month up until midnight last night
    # Otherwise, update invoices for the current month
    start_date = (Time.now - 1.day).beginning_of_month
    end_date = Time.now.beginning_of_day

    # Find all users that have owned an enterprise at some point in the current billing period (this month)
    enterprise_users = Spree::User.joins(:billable_periods)
    .where('billable_periods.begins_at >= (?) AND billable_periods.ends_at <= (?)', start_date, end_date)
    .select('DISTINCT spree_users.*')

    enterprise_users.each do |user|
      update_invoice_for(user, user.billable_periods.where('begins_at >= (?) AND ends_at <= (?)', start_date, end_date))
    end
  end

  def update_invoice_for(user, billable_periods)
    invoice = user.current_invoice

    billable_periods.each do |billable_period|
      adjustment = invoice.adjustments.where(source_id: billable_period).first
      adjustment ||= invoice.adjustments.new( adjustment_attrs_from(billable_period), :without_protection => true)
      adjustment.update_attributes( label: adjustment_label_from(billable_period), amount: billable_period.bill )
    end

    invoice.save

    finalize(invoice) if Date.today.day == 1
  end

  def adjustment_attrs_from(billable_period)
    # We should ultimately have an EnterprisePackage model, which holds all info about shop type, producer, trials, etc.
    # It should also implement a calculator that we can use here by specifying the package as the originator of the
    # adjustment, meaning that adjustments are created and updated using Spree's existing architecture.

    { source: billable_period,
      originator: nil,
      mandatory: true,
      locked: false
    }
  end

  def adjustment_label_from(billable_period)
    enterprise = billable_period.enterprise.version_at(billable_period.begins_at)
    category = enterprise.category.to_s.titleize
    category += (billable_period.trial ? " Trial" : "")
    begins = billable_period.begins_at.strftime("%d/%m/%y")
    ends = billable_period.ends_at.strftime("%d/%m/%y")

    "#{enterprise.name} (#{category}) [#{begins} - #{ends}]"
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
