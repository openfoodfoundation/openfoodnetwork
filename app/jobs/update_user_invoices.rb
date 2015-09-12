class UpdateUserInvoices
  attr_reader :start_date, :end_date

  def initialize(start_date = nil, end_date = nil)
    @start_date = start_date || (Time.now - 1.day).beginning_of_month
    @end_date = end_date || Time.now.beginning_of_day
  end

  def before(job)
    UpdateBillablePeriods.new(start_date, end_date).perform
  end

  def perform
    return unless settings_are_valid?

    # Find all users that have owned an enterprise at some point in the relevant period
    enterprise_users = Spree::User.joins(:billable_periods)
    .where('billable_periods.begins_at >= (?) AND billable_periods.ends_at <= (?) AND deleted_at IS NULL', start_date, end_date)
    .select('DISTINCT spree_users.*')

    enterprise_users.each do |user|
      billable_periods = user.billable_periods.where('begins_at >= (?) AND ends_at <= (?) AND deleted_at IS NULL', start_date, end_date).order(:enterprise_id, :begins_at)
      update_invoice_for(user, billable_periods)
    end
  end

  def update_invoice_for(user, billable_periods)
    current_adjustments = []
    invoice = user.invoice_for(start_date, end_date)

    if invoice.persisted? && invoice.created_at != start_date
      Bugsnag.notify(RuntimeError.new("InvoiceDateConflict"), {
        start_date: start_date,
        end_date: end_date,
        existing_invoice: invoice.as_json
      })
    elsif invoice.complete?
      Bugsnag.notify(RuntimeError.new("InvoiceAlreadyFinalized"), {
        invoice: invoice.as_json
      })
    else
      billable_periods.reject{ |bp| bp.turnover == 0 }.each do |billable_period|
        current_adjustments << billable_period.ensure_correct_adjustment_for(invoice)
      end
    end

    clean_up_and_save(invoice, current_adjustments)
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
      # Invoices should be "created" at the beginning of the period to which they apply
      invoice.created_at = start_date unless invoice.persisted?
      invoice.save
    else
      Bugsnag.notify(RuntimeError.new("Empty Persisted Invoice"), {
        invoice: invoice.as_json
      }) if invoice.persisted?

      invoice.destroy
    end
  end

  private

  def settings_are_valid?
    unless end_date <= Time.now
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "UpdateUserInvoices",
        error: "end_date is in the future",
        data: {
          end_date: end_date.localtime.strftime("%F %T"),
          now: Time.now.strftime("%F %T")
        }
      })
      return false
    end

    unless Enterprise.find_by_id(Spree::Config.accounts_distributor_id)
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "UpdateUserInvoices",
        error: "accounts_distributor_id is invalid",
        data: {
          accounts_distributor_id: Spree::Config.accounts_distributor_id
        }
      })
      return false
    end

    true
  end
end
