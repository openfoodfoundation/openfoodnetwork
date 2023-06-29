# frozen_string_literal: true

class TrixSanitizer
  include ActionView::Helpers::SanitizeHelper

  def sanitize_content(content)
    return if content.blank?

    sanitize(content.to_s, scrubber: TrixScrubber.new)
  end
end
