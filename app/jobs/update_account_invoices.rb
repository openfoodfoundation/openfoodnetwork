class UpdateAccountInvoices
  attr_reader :year, :month, :start_date, :end_date

  def initialize(year = nil, month = nil)
    ref_point = Time.zone.now - 1.day
    @year = year || ref_point.year
    @month = month || ref_point.month
    @start_date = Time.zone.local(@year, @month)
    @end_date = Time.zone.local(@year, @month) + 1.month
    @end_date = Time.zone.now.beginning_of_day if start_date == Time.zone.now.beginning_of_month
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
      billable_periods = account_invoice.billable_periods.order(:enterprise_id, :begins_at).reject{ |bp| bp.bill == 0 }

      if billable_periods.any?
        oldest_enterprise = billable_periods.first.enterprise
        address = oldest_enterprise.address.dup
        first, space, last = (oldest_enterprise.contact || "").partition(' ')
        address.update_attributes(phone: oldest_enterprise.phone) if oldest_enterprise.phone.present?
        address.update_attributes(firstname: first, lastname: last) if first.present? && last.present?
        account_invoice.order.update_attributes(bill_address: address, ship_address: address)
      end

      billable_periods.each do |billable_period|
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
    unless end_date <= Time.zone.now
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "UpdateAccountInvoices",
        error: "end_date is in the future",
        data: {
          end_date: end_date.in_time_zone.strftime("%F %T"),
          now: Time.zone.now.strftime("%F %T")
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
