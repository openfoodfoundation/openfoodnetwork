# frozen_string_literal: true

module Api
  module V1
    class CustomerSerializer < BaseSerializer
      attributes :id, :enterprise_id, :first_name, :last_name, :code, :email,
                 :allow_charges, :terms_and_conditions_accepted_at

      belongs_to :enterprise, links: {
        related: ->(object) {
          url_helpers.api_v1_enterprise_url(id: object.enterprise_id)
        }
      }
    end
  end
end
