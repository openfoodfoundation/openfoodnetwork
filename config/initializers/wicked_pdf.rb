WickedPdf.configure do |c|
  c.exe_path = `bundle exec which wkhtmltopdf`.chomp

  if Rails.env.test?
    # Conversion from PDF to text struggles with multi-line text.
    # We avoid that by printing on bigger pages.
    # https://github.com/openfoodfoundation/openfoodnetwork/pull/9674
    c.page_size = "A3"
  else
    c.page_size = "A4"
  end
end

# A monkey-patch to remove WickedPdf's monkey-patch, as it clashes with ViewComponents.
class WickedPdf
  module PdfHelper
    remove_method(:render)
    remove_method(:render_to_string)
  end
end
