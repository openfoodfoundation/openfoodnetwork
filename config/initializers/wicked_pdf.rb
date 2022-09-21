if Rails.env.test?
  Rails.application.reloader.to_prepare do
    WickedPdf.config = {
      #:wkhtmltopdf => '/usr/local/bin/wkhtmltopdf',
      #:layout => "pdf.html",
      :page_size => 'A3',
      :exe_path => `bundle exec which wkhtmltopdf`.chomp
    }
  end
else
  Rails.application.reloader.to_prepare do
    WickedPdf.config = {
      #:wkhtmltopdf => '/usr/local/bin/wkhtmltopdf',
      #:layout => "pdf.html",
      :page_size => 'A4', # default
      :exe_path => `bundle exec which wkhtmltopdf`.chomp
    }
  end
end

# A monkey-patch to remove WickedPdf's monkey-patch, as it clashes with ViewComponents.
class WickedPdf
  module PdfHelper
    remove_method(:render)
    remove_method(:render_to_string)
  end
end
