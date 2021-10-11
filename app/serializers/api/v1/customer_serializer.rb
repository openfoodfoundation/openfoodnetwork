# frozen_string_literal: true

module Api
  module V1
    class CustomerSerializer
      include JSONAPI::Serializer

      attributes :id, :enterprise_id, :name, :code, :email

      belongs_to :enterprise, record_type: :enterprise, serializer: :id
    end
  end
end
