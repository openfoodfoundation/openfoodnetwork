class BulkInvoiceService
  attr_reader :id

  def initialize
    @id = new_invoice_id
  end

  def start_pdf_job(order_ids)
    pdf = CombinePDF.new
    orders = Spree::Order.where(id: order_ids)

    orders.each do |order|
      invoice = renderer.render_to_string(order)

      pdf << CombinePDF.parse(invoice)
    end

    pdf.save "#{file_directory}/#{@id}.pdf"
  end
  handle_asynchronously :start_pdf_job

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

  def renderer
    @renderer ||= InvoiceRenderer.new
  end

  def file_directory
    Dir.mkdir(directory) unless File.exist?(directory)
    directory
  end
end
