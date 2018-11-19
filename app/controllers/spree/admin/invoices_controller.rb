module Spree
  module Admin
    class InvoicesController < Spree::Admin::BaseController
      def create
        Delayed::Job.enqueue BulkInvoiceJob.new(params[:order_ids], filename)

        render text: filename, status: :ok
      end

      private

      def filename
        @filename ||= Time.zone.now.to_i.to_s
      end
    end
  end
end
