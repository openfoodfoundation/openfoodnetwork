# frozen_string_literal: true

class TermsOfServiceFile < ApplicationRecord
  has_attached_file :attachment

  validates :attachment, presence: true

  # The most recently uploaded file is the current one.
  def self.current
    order(:id).last
  end

  def self.current_url
    current&.attachment&.url || Spree::Config.footer_tos_url
  end
end
