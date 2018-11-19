BulkInvoiceJob = Struct.new(:order_ids, :filename) do
  include WickedPdf::PdfHelper

  def perform
    generate_pdf
  rescue StandardError => e
    log e
  end

  private

  def generate_pdf
    pdf = CombinePDF.new
    orders = Spree::Order.where(id: order_ids)
    renderer = ApplicationController.new

    orders.each do |order|
      invoice = renderer.render_to_string pdf: "invoice-#{order.number}.pdf",
                                          template: invoice_template,
                                          formats: [:html], encoding: "UTF-8",
                                          locals: { :@order => order }

      pdf << CombinePDF.parse(invoice)
    end

    pdf.save "#{directory}/#{filename}.pdf"
  end

  def invoice_template
    Spree::Config.invoice_style2? ? "spree/admin/orders/invoice2" : "spree/admin/orders/invoice"
  end

  def log(error)
    logger = Logger.new('bulkinvoice.log')
    logger.debug e.message
    logger.debug e.backtrace[0]
  end

  def directory
    dir = 'tmp/invoices'
    Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end
end
