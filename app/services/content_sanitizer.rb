# frozen_string_literal: true

# Sanitizes and cleans up user-provided content that may contain tags, special characters, etc.

class ContentSanitizer
  include ActionView::Helpers::SanitizeHelper

  ALLOWED_TAGS = ["p", "b", "strong", "em", "i", "a", "u"].freeze
  ALLOWED_ATTRIBUTES = ["href", "target"].freeze
  FILTERED_CHARACTERS = {
    "&amp;amp;" => "&",
    "&amp;" => "&",
    "&nbsp;" => " "
  }.freeze

  def strip_content(content)
    content = strip_tags(content.to_s.strip)

    filter_characters(content) if content.length
  end

  def sanitize_content(content)
    content = sanitize(content.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)

    filter_characters(content) if content.length
  end

  private

  def filter_characters(content)
    FILTERED_CHARACTERS.each do |character, sub|
      content = content.gsub(character, sub)
    end
    content
  end
end
