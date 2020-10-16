# frozen_string_literal: true

module Api
  module Admin
    class BasicEnterpriseFeeSerializer < ActiveModel::Serializer
      attributes :id, :enterprise_id
    end
  end
end
