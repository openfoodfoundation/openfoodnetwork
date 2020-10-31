# frozen_string_literal: true

module Api
  module Admin
    class EnterpriseRoleSerializer < ActiveModel::Serializer
      attributes :id, :user_id, :enterprise_id, :user_email, :enterprise_name

      def user_email
        object.user.email
      end

      def enterprise_name
        object.enterprise.name
      end
    end
  end
end
