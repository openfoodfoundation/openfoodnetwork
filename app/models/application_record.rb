# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include DelegateBelongsTo
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

  def url_for(*args)
    Rails.application.routes.url_helpers.url_for(*args)
  end
end
