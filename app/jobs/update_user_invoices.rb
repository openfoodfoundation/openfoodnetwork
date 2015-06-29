UpdateUserInvoices = Struct.new("UpdateUserInvoices") do
  def perform
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
      adjustment = invoice.adjustments.where(source: billable_period).first
      adjustment ||= invoice.adjustments.new( adjustment_attrs_from(billable_period) )
      adjustment.label = adjustment_label_from(billable_period)
      adjustment.amount = billable_period.bill
      adjustment.save
    end

    finalize(invoice)
  end

  def adjustment_attrs_from(billable_period)
    { :source => billable_period,
      :originator => billable_period,
      :mandatory => mandatory,
      :locked => true }
  end

  def adjustment_label_from(billable_period)
    category = enterprise.version_at(billable_period.begins_at).reify.category.to_s.titleize
    category += (billable_period.trial ? " Trial" : "")
    begins = billable_period.begins_at.strftime("%d/%m")
    ends = billable_period.begins_at.strftime("%d/%m")

    "#{enterprise.name} (#{category}) [#{begins}-#{ends}]"
  end

  def finalize(invoice)
    if Date.today.day == 1
      while @order.state != "complete"
        @order.next
      end
      user.current_invoice.process
      # Mark current invoice as completed
      # Create a new invoice
      user.current_invoice = new_invoice_for(user)
    end
  end
end
