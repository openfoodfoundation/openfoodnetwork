require 'open_food_network/bill_calculator'

class BillablePeriod < ActiveRecord::Base
  belongs_to :enterprise
  belongs_to :owner, class_name: 'Spree::User'
  belongs_to :account_invoice
  has_one :adjustment, :as => :source, class_name: "Spree::Adjustment" #, :dependent => :destroy

  default_scope where(deleted_at: nil)

  def display_turnover
    Spree::Money.new(turnover, {currency: Spree::Config[:currency]})
  end

  def display_bill
    Spree::Money.new(bill, {currency: Spree::Config[:currency]})
  end

  def bill
    return 0 if trial?
    return 0 unless ['own', 'any'].include?(sells)
    OpenFoodNetwork::BillCalculator.new(turnover: turnover).bill
  end

  def label
    enterprise_version = enterprise.version_at(begins_at)
    category = enterprise_version.category.to_s.titleize
    category += (trial ? " #{I18n.t(:trial)}" : "")

    "#{enterprise_version.name} (#{category})"
  end

  def adjustment_label
    begins = begins_at.in_time_zone.strftime("%d/%m/%y")
    ends = ends_at.in_time_zone.strftime("%d/%m/%y")

    "#{label} [#{begins} - #{ends}]"
  end

  def delete
    self.update_column(:deleted_at, Time.zone.now)
  end

  def ensure_correct_adjustment_for(invoice)
    if adjustment
      # adjustment.originator = enterprise.package
      adjustment.adjustable = invoice
      adjustment.update_attributes( label: adjustment_label, amount: bill )
    else
      self.adjustment = invoice.adjustments.new( adjustment_attrs, :without_protection => true )
    end

    if Spree::Config.account_invoices_tax_rate > 0
      adjustment.set_included_tax! Spree::Config.account_invoices_tax_rate
    else
      adjustment.set_included_tax! 0
    end

    adjustment
  end

  private

  def adjustment_attrs
    # We should ultimately have an EnterprisePackage model, which holds all info about shop type, producer, trials, etc.
    # It should also implement a calculator that we can use here by specifying the package as the originator of the
    # adjustment, meaning that adjustments are created and updated using Spree's existing architecture.

    { label: adjustment_label,
      amount: bill,
      source: self,
      originator: nil, # enterprise.package
      mandatory: true,
      state: 'closed'
    }
  end
end
