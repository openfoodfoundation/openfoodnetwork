# frozen_string_literal: true

class PdfRenderer
  def render(html, display_url: default_display_url)
    display_url ||= default_display_url

    FerrumPdf.render_pdf(html: html_document(html), display_url:)
  end

  private

  def html_document(html)
    # If the string already starts like a full HTML document just return it.
    return html if html.match?(/\A\s*(<!doctype|<html)/i)

    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
      </head>
      <body>
      #{html}
      </body>
      </html>
    HTML
  end

  def default_display_url
    options = Rails.application.routes.default_url_options.symbolize_keys
    host = options.fetch(:host)
    protocol = options[:protocol].presence || "http"
    port = options[:port]

    "#{protocol}://#{host}#{":#{port}" if port}/"
  end
end
