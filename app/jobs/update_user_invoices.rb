UpdateUserInvoices = Struct.new("UpdateUserInvoices", :year, :month) do
  def start_date
    # Start at the beginning of the specified month
    # or at the beginning of the month (prior to midnight last night) if none specified
    @start_date ||= if month && year
      Time.new(year, month)
    else
      (Time.now - 1.day).beginning_of_month
    end
  end

  def end_date
    # Stop at the end of the specified month
    # or at midnight last night if no month is specified
    @end_date ||= if month && year
      Time.new(year, month) + 1.month
    else
      Time.now.beginning_of_day
    end
  end

  def perform
    return unless accounts_distributor = Enterprise.find_by_id(Spree::Config.accounts_distributor_id)

    # Find all users that have owned an enterprise at some point in the relevant period
    enterprise_users = Spree::User.joins(:billable_periods)
    .where('billable_periods.begins_at >= (?) AND billable_periods.ends_at <= (?) AND deleted_at IS NULL', start_date, end_date)
    .select('DISTINCT spree_users.*')

    enterprise_users.each do |user|
      update_invoice_for(user, user.billable_periods.where('begins_at >= (?) AND ends_at <= (?) AND deleted_at IS NULL', start_date, end_date))
    end
  end

  def update_invoice_for(user, billable_periods)
    current_adjustments = []
    invoice = user.current_invoice

    billable_periods.reject{ |bp| bp.turnover == 0 }.each do |billable_period|
      adjustment = invoice.adjustments.where(source_id: billable_period).first
      adjustment ||= invoice.adjustments.new( adjustment_attrs_from(billable_period), :without_protection => true)
      adjustment.update_attributes( label: adjustment_label_from(billable_period), amount: billable_period.bill )
      current_adjustments << adjustment
    end

    clean_up_and_save(invoice, current_adjustments)
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
    begins = billable_period.begins_at.localtime.strftime("%d/%m/%y")
    ends = billable_period.ends_at.localtime.strftime("%d/%m/%y")

    "#{enterprise.name} (#{category}) [#{begins} - #{ends}]"
  end

  def clean_up_and_save(invoice, current_adjustments)
    # Snag and then delete any obsolete adjustments
    obsolete_adjustments = invoice.adjustments.where('source_type = (?) AND id NOT IN (?)', "BillablePeriod", current_adjustments)

    if obsolete_adjustments.any?
      Bugsnag.notify(RuntimeError.new("Obsolete Adjustments"), {
        current: current_adjustments.map(&:as_json),
        obsolete: obsolete_adjustments.map(&:as_json)
      })

      obsolete_adjustments.destroy_all
    end

    if current_adjustments.any?
      invoice.save
    else
      Bugsnag.notify(RuntimeError.new("Empty Persisted Invoice"), {
        invoice: invoice.as_json
      }) if invoice.persisted?

      invoice.destroy
    end
  end
end
