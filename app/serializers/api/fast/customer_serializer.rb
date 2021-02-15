# frozen_string_literal: true

module Api
  module Fast
    class CustomerSerializer
      include JSONAPI::Serializer

      attributes :id, :enterprise_id, :name, :code, :email, :allow_charges

      belongs_to :enterprise, record_type: :enterprise
    end
  end
end