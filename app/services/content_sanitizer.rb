# frozen_string_literal: true

# Sanitizes and cleans up user-provided content that may contain tags, special characters, etc.

class ContentSanitizer
  include ActionView::Helpers::SanitizeHelper

  FILTERED_CHARACTERS = {
    "&amp;amp;" => "&",
    "&amp;" => "&",
    "&nbsp;" => " "
  }.freeze

  def strip_content(content)
    return unless content.present?

    content = strip_tags(content.to_s.strip)

    filter_characters(content)
  end

  def sanitize_content(content)
    return unless content.present?

    content = sanitize(content.to_s, scrubber: ContentScrubber.new)

    filter_characters(content)
  end

  private

  def filter_characters(content)
    FILTERED_CHARACTERS.each do |character, sub|
      content = content.gsub(character, sub)
    end
    content
  end
end
