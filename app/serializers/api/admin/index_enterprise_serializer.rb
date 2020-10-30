# frozen_string_literal: true

require 'open_food_network/enterprise_issue_validator'

module Api
  module Admin
    class IndexEnterpriseSerializer < ActiveModel::Serializer
      attributes :name, :id, :permalink, :is_primary_producer, :sells,
                 :producer_profile_only, :owned, :edit_path, :issues, :warnings

      def owned
        return true if options[:spree_current_user].admin?

        object.owner == options[:spree_current_user]
      end

      def edit_path
        edit_admin_enterprise_path(object)
      end

      def issues
        OpenFoodNetwork::EnterpriseIssueValidator.new(object).issues
      end

      def warnings
        OpenFoodNetwork::EnterpriseIssueValidator.new(object).warnings
      end
    end
  end
end
