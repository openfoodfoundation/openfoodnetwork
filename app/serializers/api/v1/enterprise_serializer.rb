# frozen_string_literal: true

module Api
  module V1
    class EnterpriseSerializer < BaseSerializer
      attributes :id, :name

      has_many :customers, links: {
        related: ->(object) {
          url_helpers.api_v1_enterprise_customers_url(enterprise_id: object.id)
        }
      }
    end
  end
end
