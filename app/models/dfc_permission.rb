# frozen_string_literal: true

# Authorisations of a user allowing a platform to access to data.
class DfcPermission < ApplicationRecord
  SCOPES = %w[
    ReadEnterprise ReadProducts ReadOrders
    WriteEnterprise WriteProducts WriteOrders
  ].freeze

  belongs_to :user, class_name: "Spree::User"
  belongs_to :enterprise

  validates :grantee, presence: true
  validates :scope, presence: true, inclusion: { in: SCOPES }
end
