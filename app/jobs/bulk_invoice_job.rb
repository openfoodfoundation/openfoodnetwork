class BulkInvoiceJob
  include WickedPdf::PdfHelper

  def initialize(order_ids, directory, filename)
    @order_ids = order_ids
    @directory = directory
    @filename = filename
  end

  def perform
    pdf = CombinePDF.new
    orders = Spree::Order.where(id: @order_ids)

    orders.each do |order|
      invoice = renderer.render_to_string pdf: "invoice-#{order.number}.pdf",
                                          template: invoice_template,
                                          formats: [:html], encoding: "UTF-8",
                                          locals: { :@order => order }

      pdf << CombinePDF.parse(invoice)
    end

    pdf.save "#{file_directory}/#{@filename}.pdf"
  end

  private

  def renderer
    ApplicationController.new
  end

  def invoice_template
    Spree::Config.invoice_style2? ? "spree/admin/orders/invoice2" : "spree/admin/orders/invoice"
  end

  def file_directory
    dir = @directory
    Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end
end
