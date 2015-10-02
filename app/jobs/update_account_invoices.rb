class UpdateAccountInvoices
  attr_reader :year, :month, :start_date, :end_date

  def initialize(year = nil, month = nil)
    ref_point = Time.now - 1.day
    @year = year || ref_point.year
    @month = month || ref_point.month
    @start_date = Time.new(@year, @month)
    @end_date = Time.new(@year, @month) + 1.month
    @end_date = Time.now.beginning_of_day if start_date == Time.now.beginning_of_month
  end

  def before(job)
    UpdateBillablePeriods.new(year, month).perform
  end

  def perform
    return unless settings_are_valid?

    account_invoices = AccountInvoice.where(year: year, month: month)
    account_invoices.each { |account_invoice| update(account_invoice) }
  end

  def update(account_invoice)
    current_adjustments = []
    unless account_invoice.order
      account_invoice.order = account_invoice.user.orders.new(distributor_id: Spree::Config[:accounts_distributor_id])
    end

    if account_invoice.order.complete?
      Bugsnag.notify(RuntimeError.new("InvoiceAlreadyFinalized"), {
        invoice_order: account_invoice.order.as_json
      })
    else
      account_invoice.billable_periods.order(:enterprise_id, :begins_at).reject{ |bp| bp.turnover == 0 }.each do |billable_period|
        current_adjustments << billable_period.ensure_correct_adjustment_for(account_invoice.order)
      end

      account_invoice.save if current_adjustments.any?

      clean_up(account_invoice.order, current_adjustments)
    end
  end

  def clean_up(invoice_order, current_adjustments)
    # Snag and then delete any obsolete adjustments
    obsolete_adjustments = invoice_order.adjustments.where('source_type = (?) AND id NOT IN (?)', "BillablePeriod", current_adjustments)

    if obsolete_adjustments.any?
      Bugsnag.notify(RuntimeError.new("Obsolete Adjustments"), {
        current: current_adjustments.map(&:as_json),
        obsolete: obsolete_adjustments.map(&:as_json)
      })

      obsolete_adjustments.destroy_all
    end

    if current_adjustments.empty?
      if invoice_order.persisted?
        Bugsnag.notify(RuntimeError.new("Empty Persisted Invoice"), {
          invoice_order: invoice_order.as_json
        })
      else
        invoice_order.destroy
      end
    end
  end

  private

  def settings_are_valid?
    unless end_date <= Time.now
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "UpdateAccountInvoices",
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
        job: "UpdateAccountInvoices",
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
