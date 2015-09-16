class FinalizeAccountInvoices
  attr_reader :start_date, :end_date

  def initialize(year = nil, month = nil)
    ref_point = Time.now - 1.month
    @year = year || ref_point.year
    @month = month || ref_point.month
    @start_date = Time.new(@year, @month)
    @end_date = Time.new(@year, @month) + 1.month
  end

  def before(job)
    UpdateBillablePeriods.new(year, month).perform
    UpdateAccountInvoices.new(year, month).perform
  end

  def perform
    return unless settings_are_valid?

    invoices = Spree::Order.where('distributor_id = (?) AND created_at >= (?) AND created_at < (?) AND completed_at IS NULL',
      @accounts_distributor, start_date, end_date)

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

  private

  def settings_are_valid?
    unless end_date <= Time.now
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "FinalizeAccountInvoices",
        error: "end_date is in the future",
        data: {
          end_date: end_date.localtime.strftime("%F %T"),
          now: Time.now.strftime("%F %T")
        }
      })
      return false
    end

    unless @accounts_distributor = Enterprise.find_by_id(Spree::Config.accounts_distributor_id)
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "FinalizeAccountInvoices",
        error: "accounts_distributor_id is invalid",
        data: {
          accounts_distributor_id: Spree::Config.accounts_distributor_id
        }
      })
      return false
    end

    unless @accounts_distributor.payment_methods.find_by_id(Spree::Config.default_accounts_payment_method_id)
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "FinalizeAccountInvoices",
        error: "default_accounts_payment_method_id is invalid",
        data: {
          default_accounts_payment_method_id: Spree::Config.default_accounts_payment_method_id
        }
      })
      return false
    end

    unless @accounts_distributor.shipping_methods.find_by_id(Spree::Config.default_accounts_shipping_method_id)
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "FinalizeAccountInvoices",
        error: "default_accounts_shipping_method_id is invalid",
        data: {
          default_accounts_shipping_method_id: Spree::Config.default_accounts_shipping_method_id
        }
      })
      return false
    end

    true
  end
end
