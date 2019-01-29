class BulkInvoiceService
  include WickedPdf::PdfHelper
  attr_reader :id

  def initialize
    @id = new_invoice_id
  end

  def start_pdf_job(order_ids)
    pdf = CombinePDF.new
    orders = Spree::Order.where(id: order_ids)

    orders.each do |order|
      invoice = renderer.render_to_string pdf: "invoice-#{order.number}.pdf",
                                          template: invoice_template,
                                          formats: [:html], encoding: "UTF-8",
                                          locals: { :@order => order }

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
    ApplicationController.new
  end

  def invoice_template
    Spree::Config.invoice_style2? ? "spree/admin/orders/invoice2" : "spree/admin/orders/invoice"
  end

  def file_directory
    Dir.mkdir(directory) unless File.exist?(directory)
    directory
  end
end
