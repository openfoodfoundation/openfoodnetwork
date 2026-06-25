# frozen_string_literal: true

class TrixSanitizer
  include ActionView::Helpers::SanitizeHelper

  def sanitize_content(content)
    return if content.blank?

    html = sanitize(content.to_s, scrubber: TrixScrubber.new)
    strip_leading_empty_blocks(html)
  end

  private

  def strip_leading_empty_blocks(html)
    fragment = Nokogiri::HTML.fragment(html)
    empties = fragment.children.take_while do |node|
      node.element? && node.text.strip.empty? && node.css('img').empty?
    end
    empties.each(&:remove)
    fragment.to_html
  end
end
