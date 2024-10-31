# frozen_string_literal: true

class SanitizeHtmlAttributes < ActiveRecord::Migration[7.0]
  class CustomTab < ApplicationRecord
  end

  class EnterpriseGroup < ApplicationRecord
  end

  class SpreeProduct < ApplicationRecord
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
      @sanitizer.sanitize(
        html, tags: ALLOWED_TAGS, attributes: (ALLOWED_ATTRIBUTES + ALLOWED_TRIX_DATA_ATTRIBUTES)
      )
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
  end

  def up
    CustomTab.where.not(content: [nil, ""]).find_each do |row|
      sane = HtmlSanitizer.sanitize(row.content)
      row.update_column(:content, sane)
    end
    EnterpriseGroup.where.not(long_description: [nil, ""]).find_each do |row|
      sane = HtmlSanitizer.sanitize_and_enforce_link_target_blank(row.long_description)
      row.update_column(:long_description, sane)
    end
    SpreeProduct.where.not(description: [nil, ""]).find_each do |row|
      sane = HtmlSanitizer.sanitize(row.description)
      row.update_column(:description, sane)
    end
  end
end
