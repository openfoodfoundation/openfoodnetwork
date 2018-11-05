require 'combine_pdf'

module Spree
  module Admin
    class InvoicesController < Spree::Admin::BaseController
      def show
        combined_pdf = CombinePDF.new

        Spree::Order.where(id: params[:order_ids]).each do |order|
          @order = order
          pdf_data = render_to_string pdf: "invoice-#{order.number}.pdf",
                                      template: invoice_template,
                                      formats: [:html], encoding: "UTF-8"

          combined_pdf << CombinePDF.parse(pdf_data)
        end

        send_data combined_pdf.to_pdf, filename: "invoices.pdf",
                                       type: "application/pdf", disposition: :inline
      end

      private

      def invoice_template
        Spree::Config.invoice_style2? ? "spree/admin/orders/invoice2" : "spree/admin/orders/invoice"
      end
    end
  end
end
