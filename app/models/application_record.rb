# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Spree::Core::Permalinks
  include Spree::Preferences::Preferable
  include Searchable
  include ArelHelpers::ArelTable
  include ArelHelpers::Aliases
  include ArelHelpers::JoinAssociation

  self.abstract_class = true

  def self.image_service
    ENV["S3_BUCKET"].present? ? :amazon_public : :local
  end

  # We might have a development environment without S3 but with a database
  # dump pointing to S3 images. Accessing the service fails then.
  def image_variant_url_for(variant)
    if ENV["S3_BUCKET"].present? && variant.service.public?
      variant.processed.url
    else
      unless variant.blob.persisted?
        raise "ActiveStorage blob for variant is not persisted. Cannot generate URL."
      end

      url_for(variant)
    end
  end

  def url_for(*args)
    Rails.application.routes.url_helpers.url_for(*args)
  end
end
