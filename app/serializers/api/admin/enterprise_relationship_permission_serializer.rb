# frozen_string_literal: true

module Api
  module Admin
    class EnterpriseRelationshipPermissionSerializer < ActiveModel::Serializer
      attributes :id, :name
    end
  end
end
