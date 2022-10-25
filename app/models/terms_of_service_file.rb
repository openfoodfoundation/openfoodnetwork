# frozen_string_literal: true

class TermsOfServiceFile < ApplicationRecord
  has_one_attached :attachment

  validates :attachment, attached: true

  # The most recently uploaded file is the current one.
  def self.current
    order(:id).last
  end

  def self.current_url
    if current
      Rails.application.routes.url_helpers.url_for(current.attachment)
    else
      Spree::Config.footer_tos_url
    end
  end

  # If no file has been uploaded, we don't know when the old terms have
  # been updated last. So we return the most recent possible update time.
  def self.updated_at
    current&.updated_at || Time.zone.now
  end
end
