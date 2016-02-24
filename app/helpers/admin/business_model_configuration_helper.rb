module Admin
  module BusinessModelConfigurationHelper
    def monthly_bill_description
      plus = monthly_bill_includes_fixed? && monthly_bill_includes_rate? ? " + " : ""

      if fixed_description.empty? && rate_description.empty?
        t(:free).upcase
      elsif monthly_bill_includes_cap? && monthly_bill_includes_rate? # only care about cap if there is a rate too
        "#{fixed_description}#{plus}#{rate_description}{joiner}#{cap_description} #{t(:per_month).upcase}#{tax_description.upcase}"
      else
        "#{fixed_description}#{plus}#{rate_description} #{t(:per_month).upcase}#{tax_description.upcase}"
      end
    end

    private

    def fixed_description
      fixed_amount = Spree::Money.new(Spree::Config[:account_invoices_monthly_fixed], {currency: Spree::Config[:currency]} ).rounded
      monthly_bill_includes_fixed? ? "#{fixed_amount}" : ""
    end

    def rate_description
      percentage = (Spree::Config[:account_invoices_monthly_rate]*100).round(2)
      monthly_bill_includes_rate? ? t(:percentage_of_sales, percentage: "#{percentage}%").upcase : ""
    end

    def cap_description
      cap_amount = Spree::Money.new(Spree::Config[:account_invoices_monthly_cap], { currency: Spree::Config[:currency] }).rounded
      monthly_bill_includes_cap? ? "#{t(:capped_at_cap, cap: cap_amount).upcase}" : ""
    end

    def tax_description
      Spree::Config[:account_invoices_tax_rate] > 0 ? ", #{t(:plus_tax).upcase}" : ""
    end

    def monthly_bill_includes_fixed?
      Spree::Config[:account_invoices_monthly_fixed] > 0
    end

    def monthly_bill_includes_rate?
      Spree::Config[:account_invoices_monthly_rate] > 0
    end

    def monthly_bill_includes_cap?
      Spree::Config[:account_invoices_monthly_cap] > 0
    end
  end
end
