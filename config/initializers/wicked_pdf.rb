Rails.application.reloader.to_prepare do
  WickedPdf.config = {
    #:wkhtmltopdf => '/usr/local/bin/wkhtmltopdf',
    #:layout => "pdf.html",
    :exe_path => `bundle exec which wkhtmltopdf`.chomp
  }
end

# A monkey-patch to remove WickedPdf's monkey-patch, as it clashes with ViewComponents.
class WickedPdf
  module PdfHelper
    remove_method(:render)
    remove_method(:render_to_string)
  end
end
