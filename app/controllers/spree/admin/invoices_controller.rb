# frozen_string_literal: true

module Spree
  module Admin
    class InvoicesController < Spree::Admin::BaseController
      respond_to :json
      authorize_resource class: false

      def create
        invoice_service = BulkInvoiceService.new
        invoice_service.start_pdf_job(params[:order_ids])

        render json: invoice_service.id, status: :ok
      end

      def show
        invoice_id = params[:id]
        invoice_pdf = BulkInvoiceService.new.filepath(invoice_id)

        send_file(invoice_pdf, type: 'application/pdf', disposition: :inline)
      end

      def poll
        invoice_id = params[:invoice_id]

        if BulkInvoiceService.new.invoice_created? invoice_id
          render json: { created: true }, status: :ok
        else
          render json: { created: false }, status: :unprocessable_entity
        end
      end
    end
  end
end
