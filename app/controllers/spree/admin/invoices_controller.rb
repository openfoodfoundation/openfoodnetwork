# frozen_string_literal: true

module Spree
  module Admin
    class InvoicesController < Spree::Admin::BaseController
      respond_to :json

      def index
        @order = Spree::Order.find_by(number: params[:order_id])
        authorize! :invoice, @order
      end

      def create
        invoice_service = BulkInvoiceService.new
        invoice_service.start_pdf_job(params[:order_ids])

        render json: invoice_service.id, status: :ok
      end

      def generate
        @order = Order.find_by(number: params[:order_id])
        @comparator = OrderInvoiceComparator.new(@order)
        if @comparator.can_generate_new_invoice?
          @order.invoices.create!(
            date: Time.zone.today,
            number: @order.invoices.count + 1,
            data: invoice_data
          )
        elsif @comparator.can_update_latest_invoice?
          @order.invoices.last.update!(
            date: Time.zone.today,
            data: invoice_data
          )
        end
        redirect_back(fallback_location: spree.admin_dashboard_path)
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

      protected

      def invoice_data
        @invoice_data ||= InvoiceDataGenerator.new(@order).generate
      end
    end
  end
end
