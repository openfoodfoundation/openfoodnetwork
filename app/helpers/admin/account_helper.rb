module Admin
  module AccountHelper
    def invoice_description_for(invoice)
      month = t(:abbr_month_names, :scope => :date)[invoice.month]
      year = invoice.year
      star = invoice.order.nil? || invoice.order.completed? ? "" : "*"
      "#{month} #{year}#{star}"
    end

    def invoice_total_for(invoice)
      invoice.order.andand.display_total || Spree::Money.new(0, { :currency => Spree::Config[:currency] })
    end
  end
end
