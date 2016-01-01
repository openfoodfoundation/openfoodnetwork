class UpdateBillablePeriods
  attr_reader :year, :month, :start_date, :end_date

  def initialize(year = nil, month = nil)
    ref_point = Time.zone.now - 1.day
    @year = year || ref_point.year
    @month = month || ref_point.month
    @start_date = Time.zone.local(@year, @month)
    @end_date = Time.zone.local(@year, @month) + 1.month
    @end_date = Time.zone.now.beginning_of_day if start_date == Time.zone.now.beginning_of_month
  end

  def perform
    return unless settings_are_valid?

    job_start_time = Time.zone.now

    enterprises = Enterprise.where('created_at < (?)', end_date).select([:id, :name, :owner_id, :sells, :shop_trial_start_date, :created_at])

    # Cycle through enterprises
    enterprises.each do |enterprise|
      start_for_enterprise = [start_date, enterprise.created_at].max
      end_for_enterprise = [end_date].min # [end_date, enterprise.deleted_at].min

      # Cycle through previous versions of this enterprise
      versions = enterprise.versions.where('created_at >= (?) AND created_at < (?)', start_for_enterprise, end_for_enterprise).order(:created_at)

      trial_start = enterprise.shop_trial_start_date
      trial_expiry = enterprise.shop_trial_expiry

      versions.each do |version|
        begins_at = version.previous.andand.created_at || start_for_enterprise
        ends_at = version.created_at

        split_for_trial(version.reify, begins_at, ends_at, trial_start, trial_expiry)
      end

      # Update / create billable_period for current start
      begins_at = versions.last.andand.created_at || start_for_enterprise
      ends_at = end_date

      split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)

      clean_up_untouched_billable_periods_for(enterprise, job_start_time)
    end
  end

  def split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
    trial_start = trial_expiry = begins_at-1.day if trial_start.nil? || trial_expiry.nil?

    # If the trial begins after ends_at, create a bill for the entire period
    # Otherwise, create a normal billable_period from the begins_at until the start of the trial
    if trial_start > begins_at
      update_billable_period(enterprise, begins_at, [ends_at, trial_start].min, false)
    end

    # If all or some of the trial occurs between begins_at and ends_at
    # Create a trial billable_period from the from begins_at or trial_start, whichever occurs last, until ends_at, or trial_expiry whichever occurs first
    if trial_expiry >= begins_at && trial_start <= ends_at
      update_billable_period(enterprise, [trial_start, begins_at].max, [ends_at, trial_expiry].min, true)
    end

    # If the trial finishes before begins_at, or trial has not been set, create a bill for the entire period
    # Otherwise, create a normal billable_period from the end of the trial until ends_at
    if trial_expiry < ends_at
      update_billable_period(enterprise, [trial_expiry, begins_at].max, ends_at, false)
    end
  end

  def update_billable_period(enterprise, begins_at, ends_at, trial)
    owner_id = enterprise.owner_id
    sells = enterprise.sells
    orders = Spree::Order.where('distributor_id = (?) AND completed_at >= (?) AND completed_at < (?)', enterprise.id, begins_at, ends_at)
    account_invoice = AccountInvoice.find_or_create_by_user_id_and_year_and_month(owner_id, begins_at.year, begins_at.month)

    billable_period = BillablePeriod.where(account_invoice_id: account_invoice.id, begins_at: begins_at, enterprise_id: enterprise.id).first

    unless account_invoice.order.andand.complete?
      billable_period ||= BillablePeriod.new(account_invoice_id: account_invoice.id, begins_at: begins_at, enterprise_id: enterprise.id)
      billable_period.update_attributes({
        ends_at: ends_at,
        sells: sells,
        trial: trial,
        owner_id: owner_id,
        turnover: orders.sum(&:total)
      })
    end

    billable_period.touch
  end

  def clean_up_untouched_billable_periods_for(enterprise, job_start_time)
    # Snag and then delete any BillablePeriods which overlap
    obsolete_billable_periods = enterprise.billable_periods.where('ends_at > (?) AND begins_at < (?) AND billable_periods.updated_at < (?)', start_date, end_date, job_start_time)

    if obsolete_billable_periods.any?
      current_billable_periods = enterprise.billable_periods.where('ends_at >= (?) AND begins_at <= (?) AND billable_periods.updated_at > (?)', start_date, end_date, job_start_time)

      Delayed::Worker.logger.info "#{enterprise.name} #{start_date.strftime("%F %T")} #{job_start_time.strftime("%F %T")}"
      Delayed::Worker.logger.info "#{obsolete_billable_periods.first.updated_at.strftime("%F %T")}"

      Bugsnag.notify(RuntimeError.new("Obsolete BillablePeriods"), {
        current: current_billable_periods.map(&:as_json),
        obsolete: obsolete_billable_periods.map(&:as_json)
      })
    end

    obsolete_billable_periods.includes({ account_invoice: :order}).
    where('spree_orders.state <> \'complete\' OR account_invoices.order_id IS NULL').
    each(&:delete)
  end

  private

  def settings_are_valid?
    unless end_date <= Time.zone.now
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "UpdateBillablePeriods",
        error: "end_date is in the future",
        data: {
          end_date: end_date.in_time_zone.strftime("%F %T"),
          now: Time.zone.now.strftime("%F %T")
        }
      })
      return false
    end

    true
  end
end
