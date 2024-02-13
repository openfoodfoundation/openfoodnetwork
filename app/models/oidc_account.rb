# frozen_string_literal: true

class OidcAccount < ApplicationRecord
  belongs_to :user, class_name: "Spree::User"

  # When a user authenticates via token, the `uid` should be mapped to only one
  # OFN user and therefore it needs to be unique.
  validates :uid, presence: true, uniqueness: true
end
