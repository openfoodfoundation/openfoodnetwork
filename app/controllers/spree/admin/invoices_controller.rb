module Spree
  module Admin
    class InvoicesController < Spree::Admin::BaseController
      respond_to :json

      def create
        Delayed::Job.enqueue BulkInvoiceJob.new(params[:order_ids], directory, filename)

        render text: filename, status: :ok
      end

      def show
        invoice_id = params[:id]

        send_file(filepath(invoice_id), type: 'application/pdf', disposition: :inline)
      end

      def poll
        invoice_id = params[:invoice_id]

        if File.exist? filepath(invoice_id)
          render json: { created: true }, status: :ok
        else
          render json: { created: false }, status: :unprocessable_entity
        end
      end

      private

      def filename
        @filename ||= Time.zone.now.to_i.to_s
      end

      def directory
        'tmp/invoices'
      end

      def filepath(invoice_id)
        @filepath ||= "#{directory}/#{invoice_id}.pdf"
      end
    end
  end
end
