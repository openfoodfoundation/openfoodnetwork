# frozen_string_literal: true

class SanitizeEnterpriseLongDescription < ActiveRecord::Migration[7.0]
  class Enterprise < ApplicationRecord
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
  end

  def up
    Enterprise.where.not(long_description: [nil, ""]).find_each do |enterprise|
      long_description = HtmlSanitizer.sanitize(enterprise.long_description)
      enterprise.update!(long_description:)
    end
  end

  private

  def sanitize(html)
    HtmlSanitizer.sanitize(html)
  end
end
