# frozen_string_literal: true

module Api
  module V1
    class IdSerializer
      include JSONAPI::Serializer

      attributes :id
    end
  end
end
