# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Spree::Core::Permalinks
  include Spree::Preferences::Preferable
  include Searchable
  include ArelHelpers::ArelTable
  include ArelHelpers::Aliases
  include ArelHelpers::JoinAssociation

  self.abstract_class = true
  self.include_root_in_json = true

  def self.image_service
    return :local if ENV["S3_BUCKET"].blank?
    return :amazon_public if ENV["S3_ENDPOINT"].blank?

    :s3_compatible_storage_public
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

  def url_for(*)
    Rails.application.routes.url_helpers.url_for(*)
  end
end
