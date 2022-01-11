# frozen_string_literal: false

require 'spec_helper'
require 'spree/payment_methods_helper'

describe BulkInvoiceService do
  include ActiveJob::TestHelper
  include Spree::PaymentMethodsHelper

  let(:service) { BulkInvoiceService.new }

  describe "#start_pdf_job" do
    it "starts a background process to create a pdf with multiple invoices" do
      expect do
        service.start_pdf_job [1, 2]
      end.to enqueue_job BulkInvoiceJob
    end

    it "creates a PDF invoice" do
      order = create(:completed_order_with_fees)
      order.bill_address = order.ship_address
      order.save!

      perform_enqueued_jobs do
        service.start_pdf_job([order.id])
      end

      expect(service.invoice_created?(service.id)).to be_truthy
    end
  end

  describe "#invoice_created?" do
    context "when the invoice has been created" do
      it "returns true" do
        allow(File).to receive(:exist?).and_return(true)

        created = service.invoice_created? '45891723'
        expect(created).to be_truthy
      end
    end

    context "when the invoice has not been created" do
      it "returns false" do
        created = service.invoice_created? '1234567'
        expect(created).to_not be_truthy
      end
    end
  end

  describe "#filepath" do
    it "returns the filepath of a given invoice" do
      filepath = service.filepath '1234567'
      expect(filepath).to eq 'tmp/invoices/1234567.pdf'
    end
  end
end
