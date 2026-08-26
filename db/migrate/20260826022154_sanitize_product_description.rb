# frozen_string_literal: true

class SanitizeProductDescription < ActiveRecord::Migration[7.1]
  class SpreeProduct < ApplicationRecord
    self.table_name = "spree_products"
  end

  # This is a copy from our application code at the time of writing.
  # We prefer to keep migrations isolated and not affected by changing
  # application code in the future.
  # If we need to change the sanitizer in the future we may need a new
  # migration (not change the old one) to sanitise the data properly.
  class HtmlSanitizer
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
  end

  def up
    SpreeProduct.where.not(description: [nil, ""]).find_each do |product|
      description = HtmlSanitizer.sanitize(product.description)
      product.update!(description:)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
