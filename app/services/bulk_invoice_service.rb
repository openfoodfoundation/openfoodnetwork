# frozen_string_literal: true

class BulkInvoiceService
  attr_reader :id

  def initialize
    @id = new_invoice_id
  end

  def start_pdf_job(order_ids)
    BulkInvoiceJob.perform_later order_ids, "#{file_directory}/#{@id}.pdf"
  end

  def invoice_created?(invoice_id)
    File.exist? filepath(invoice_id)
  end

  def filepath(invoice_id)
    "#{directory}/#{invoice_id}.pdf"
  end

  private

  def new_invoice_id
    Time.zone.now.to_i.to_s
  end

  def directory
    'tmp/invoices'
  end

  def file_directory
    Dir.mkdir(directory) unless File.exist?(directory)
    directory
  end
end
