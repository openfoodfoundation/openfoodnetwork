# frozen_string_literal: true

class OidcAccount < ApplicationRecord
  belongs_to :user, class_name: "Spree::User"

  # When a user authenticates via token, the `uid` should be mapped to only one
  # OFN user and therefore it needs to be unique.
  validates :uid, presence: true, uniqueness: true

  def self.link(user, auth)
    attributes = {
      user_id: user.id,
      provider: auth.provider,
      uid: auth.uid,
      token: auth.dig(:credentials, :token),
      refresh_token: auth.dig(:credentials, :refresh_token),
    }
    # This skips validations but we have database constraints in place.
    # We may replace this at some point.
    upsert_all([attributes], unique_by: [:user_id]) # rubocop:disable Rails/SkipsModelValidations
  end
end
