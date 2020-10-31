# frozen_string_literal: true

module Api
  module Admin
    class EnterpriseRelationshipSerializer < ActiveModel::Serializer
      attributes :id, :parent_id, :parent_name, :child_id, :child_name

      has_many :permissions

      def parent_name
        object.parent.name
      end

      def child_name
        object.child.name
      end
    end
  end
end
