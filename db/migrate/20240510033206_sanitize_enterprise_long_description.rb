# frozen_string_literal: true

class SanitizeEnterpriseLongDescription < ActiveRecord::Migration[7.0]
  class Enterprise < ApplicationRecord
  end

  def up
    Enterprise.where.not(long_description: [nil, ""]).find_each do |enterprise|
      enterprise.update!(long_description: sanitize(long_description))
    end
  end

  private

  def sanitize(html)
    @sanitizer ||= Rails::HTML::SafeListSanitizer.new
    @sanitizer.sanitize(
      html, tags: %w[h1 h2 h3 h4 p b i u a], attributes: %w[href target],
    )
  end
end
