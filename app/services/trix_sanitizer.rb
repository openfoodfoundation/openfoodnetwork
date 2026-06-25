# frozen_string_literal: true

class TrixSanitizer
  include ActionView::Helpers::SanitizeHelper

  def sanitize_content(content)
    return if content.blank?

    html = sanitize(content.to_s, scrubber: TrixScrubber.new)
    strip_leading_whitespace(html)
  end

  private

  def strip_leading_whitespace(html)
    fragment = Nokogiri::HTML.fragment(html)

    # Remove empty leading block elements (e.g. <div><br></div>)
    empties = fragment.children.take_while do |node|
      node.element? && node.text.strip.empty? && node.css('img').empty?
    end
    empties.each(&:remove)

    # Strip <br> elements that appear before any visible text
    strip_leading_brs_from!(fragment)

    fragment.to_html
  end

  # Depth-first removal of leading <br> nodes before any visible text.
  # Returns :stop when real text is found (signal to stop stripping).
  def strip_leading_brs_from!(node)
    node.children.to_a.each do |child|
      if child.text? && child.text.strip.present?
        return :stop
      elsif child.name == 'br'
        child.remove
      elsif child.element?
        return :stop if strip_leading_brs_from!(child) == :stop
      end
    end
    :continue
  end
end
