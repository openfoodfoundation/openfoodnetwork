module OpenFoodNetwork
  class BillCalculator
    attr_accessor :turnover, :fixed, :rate, :cap, :tax_rate, :min_bill_to

    def initialize(opts={})
      @turnover = opts[:turnover] || 0
      @fixed = opts[:fixed] || Spree::Config[:account_invoices_monthly_fixed]
      @rate = opts[:rate] || Spree::Config[:account_invoices_monthly_rate]
      @cap = opts[:cap] || Spree::Config[:account_invoices_monthly_cap]
      @tax_rate = opts[:tax_rate] || Spree::Config[:account_invoices_tax_rate]
      @min_bill_to = opts[:min_bill_to] || Spree::Config[:minimum_billable_turnover]
    end

    def bill
      bill = fixed + (turnover * rate)
      bill = cap > 0 ? [bill, cap].min : bill
      bill = turnover > min_bill_to ? bill : 0
      bill * (1 + tax_rate)
    end
  end
end
