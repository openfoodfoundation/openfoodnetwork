# frozen_string_literal: true

class OidcAccount < ApplicationRecord
  belongs_to :user, class_name: "Spree::User"

  # When a user authenticates via token, the `uid` should be mapped to only one
  # OFN user and therefore it needs to be unique.
  validates :uid, presence: true, uniqueness: true

  def self.link(user, auth)
    upsert_all(
      [{user_id: user.id, provider: auth.provider, uid: auth.uid}],
      unique_by: [:user_id]
    )
  end
end
