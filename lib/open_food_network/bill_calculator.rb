module OpenFoodNetwork
  class BillCalculator
    attr_accessor :turnover, :fixed, :rate, :cap, :tax_rate, :minimum_billable_turnover

    def initialize(opts={})
      @turnover = opts[:turnover] || 0
      @fixed = opts[:fixed] || Spree::Config[:account_invoices_monthly_fixed]
      @rate = opts[:rate] || Spree::Config[:account_invoices_monthly_rate]
      @cap = opts[:cap] || Spree::Config[:account_invoices_monthly_cap]
      @tax_rate = opts[:tax_rate] || Spree::Config[:account_invoices_tax_rate]
      @minimum_billable_turnover = opts[:minimum_billable_turnover] || Spree::Config[:minimum_billable_turnover]
    end

    def bill
      return 0 if turnover < minimum_billable_turnover
      bill = fixed + (turnover * rate)
      bill = [bill, cap].min if cap > 0
      bill * (1 + tax_rate)
    end
  end
end
