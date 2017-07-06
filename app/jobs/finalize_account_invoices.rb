# This class is part of the system that charges hubs for using OFN. It does so
# by creating orders. These are not orders for food that customers place, but
# instead are orders for OFN usage, so to speak. Thus, they're technically not
# "shipped" anywhere, so they're just given a default shipping method.
#
# The "orders" used by this class are not real orders, they are basically
# "invoices" that enterprise owners need to pay for use of an open food network
# instance. The amount that the enterprise owner is charged is configurable by
# the instance, and can be based on a combination of a percentage of their
# turnover, fixed fees, caps and floors and trial periods. This "orders" hold
# the billing information for a particular enterprise owner for a given month.
#
# We assign them also a default shipping method because there is a validation
# on Spree::Shipment that requires it.
class FinalizeAccountInvoices
  attr_reader :year, :month, :start_date, :end_date

  def initialize(year = nil, month = nil)
    ref_point = Time.zone.now - 1.month
    @year = year || ref_point.year
    @month = month || ref_point.month
    @start_date = Time.zone.local(@year, @month)
    @end_date = Time.zone.local(@year, @month) + 1.month
  end

  def before(job)
    UpdateBillablePeriods.new(year, month).perform
    UpdateAccountInvoices.new(year, month).perform
  end

  def perform
    return unless settings_are_valid?


    invoice_orders = AccountInvoice.where(year: year, month: month).map(&:order)
    invoice_orders.select{ |order| order.present? && order.completed_at.nil? }.each{ |order| finalize(order) }
  end

  def finalize(invoice_order)
    # TODO: When we implement per-customer and/or per-user preferences around shipping and payment methods
    # we can update these to read from those preferences
    invoice_order.payments.create(payment_method_id: Spree::Config.default_accounts_payment_method_id, amount: invoice_order.total)
    invoice_order.update_attribute(:shipping_method_id, Spree::Config.default_accounts_shipping_method_id)
    while invoice_order.state != "complete"
      if invoice_order.errors.any?
        Bugsnag.notify(RuntimeError.new("FinalizeInvoiceError"), {
          job: "FinalizeAccountInvoices",
          error: "Cannot finalize invoice due to errors",
          data: {
            errors: invoice_order.errors.full_messages
          }
        })
        break
      else
        invoice_order.next
      end
    end
  end

  private

  def settings_are_valid?
    unless end_date <= Time.zone.now
      Bugsnag.notify(RuntimeError.new("InvalidJobSettings"), {
        job: "FinalizeAccountInvoices",
        error: "end_date is in the future",
        data: {
          end_date: end_date.in_time_zone.strftime("%F %T"),
          now: Time.zone.now.strftime("%F %T")
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
