# frozen_string_literal: true

# Keeps only allowed HTML.
#
# We store some rich text as HTML in attributes of models like Enterprise.
# We offer an editor which supports certain tags but you can't insert just any
# HTML, which would be dangerous.
class HtmlSanitizer
  ALLOWED_TAGS = %w[h1 h2 h3 h4 div p br b i u a strong em del pre blockquote ul ol li hr
                    figure].freeze
  ALLOWED_ATTRIBUTES = %w[href target].freeze
  ALLOWED_TRIX_DATA_ATTRIBUTES = %w[data-trix-attachment].freeze

  def self.sanitize(html)
    @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    @sanitizer.sanitize(
      html, tags: ALLOWED_TAGS, attributes: (ALLOWED_ATTRIBUTES + ALLOWED_TRIX_DATA_ATTRIBUTES)
    )
  end
end
