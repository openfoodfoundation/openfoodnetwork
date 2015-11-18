module OpenFoodNetwork
  class BillCalculator
    attr_accessor :turnover, :fixed, :rate, :cap, :tax_rate

    def initialize(opts={})
      @turnover = opts[:turnover] || 0
      @fixed = opts[:fixed] || Spree::Config[:account_invoices_monthly_fixed]
      @rate = opts[:rate] || Spree::Config[:account_invoices_monthly_rate]
      @cap = opts[:cap] || Spree::Config[:account_invoices_monthly_cap]
      @tax_rate = opts[:tax_rate] || Spree::Config[:account_invoices_tax_rate]
    end

    def bill
      bill = fixed + (turnover * rate)
      bill = bill * (1 + tax_rate)
      return bill unless cap > 0
      [bill, cap].min
    end
  end
end
