# frozen_string_literal: true

# Keeps only allowed HTML.
#
# We store some rich text as HTML in attributes of models like Enterprise.
# We offer an editor which supports certain tags but you can't insert just any
# HTML, which would be dangerous.
class HtmlSanitizer
  # div is required by Trix editor
  ALLOWED_TAGS = %w[h1 h2 h3 h4 div p br b i u a strong em del pre blockquote ul ol li hr
                    figure].freeze
  ALLOWED_ATTRIBUTES = %w[href target].freeze
  ALLOWED_TRIX_DATA_ATTRIBUTES = %w[data-trix-attachment].freeze

  def self.sanitize(html)
    @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    sanitized = @sanitizer.sanitize(
      html, tags: ALLOWED_TAGS, attributes: (ALLOWED_ATTRIBUTES + ALLOWED_TRIX_DATA_ATTRIBUTES)
    )
    strip_leading_whitespace(sanitized)
  end

  def self.sanitize_and_enforce_link_target_blank(html)
    sanitize(enforce_link_target_blank(html))
  end

  def self.enforce_link_target_blank(html)
    return if html.nil?

    Nokogiri::HTML::DocumentFragment.parse(html).tap do |document|
      document.css("a").each { |link| link["target"] = "_blank" }
    end.to_s
  end

  def self.strip_leading_whitespace(html)
    return html if html.blank?

    fragment = Nokogiri::HTML.fragment(html)
    return html if fragment.text.strip.empty?

    # Remove empty leading block elements (e.g. <div><br></div>), but not
    # standalone void elements (e.g. a lone <hr> divider is real content).
    empties = fragment.children.take_while do |node|
      node.element? && !node.children.empty? && node.text.strip.empty?
    end
    empties.each(&:remove)

    # Strip <br> elements that appear before any visible text
    strip_leading_brs_from!(fragment)

    fragment.to_html(save_with: 0)
  end
  private_class_method :strip_leading_whitespace

  # Depth-first removal of leading <br> nodes before any visible text.
  # Returns :stop when real text is found (signal to stop stripping).
  def self.strip_leading_brs_from!(node)
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
  private_class_method :strip_leading_brs_from!
end
