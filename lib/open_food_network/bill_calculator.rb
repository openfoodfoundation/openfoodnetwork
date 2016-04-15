  module OpenFoodNetwork
  class BillCalculator
    attr_accessor :turnover, :fixed, :rate, :cap, :tax_rate, :min_bill_to

    def initialize(opts={})
      defaults = {
        fixed: :account_invoices_monthly_fixed
        rate: :account_invoices_monthly_rate
        cap: :account_invoices_monthly_cap
        tax_rate: :account_invoices_tax_rate
        min_bill_to: :minimum_billable_turnover
      }
      defaults.each do |key, config|
        this[key] = opts[key] || Spree::Config[config]
      end
    end

    def bill
      bill = fixed + (turnover * rate)
      bill = [bill, cap].min if cap > 0
      bill = turnover > min_bill_to ? bill : 0
      bill * (1 + tax_rate)
    end
end
