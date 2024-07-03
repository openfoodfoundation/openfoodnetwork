# frozen_string_literal: true

module Spree
  module Admin
    class InvoicesController < Spree::Admin::BaseController
      respond_to :json

      def index
        @order = Spree::Order.find_by(number: params[:order_id])
        authorize! :invoice, @order
      end

      def show
        invoice_id = params[:id]
        invoice_pdf = filepath(invoice_id)

        send_file(invoice_pdf, type: 'application/pdf', disposition: :inline)
      rescue ActionController::MissingFile
        render "errors/not_found", status: :not_found, formats: :html
      end

      def generate
        @order = Order.find_by(number: params[:order_id])
        if @order.distributor.can_invoice?
          authorize! :invoice, @order
          ::Orders::GenerateInvoiceService.new(@order).generate_or_update_latest_invoice
        else
          flash[:error] = t(:must_have_valid_business_number,
                            enterprise_name: @order.distributor.name)
        end
        redirect_back(fallback_location: spree.admin_dashboard_path)
      end

      private

      def filepath(invoice_id)
        "tmp/invoices/#{invoice_id}.pdf"
      end
    end
  end
end
