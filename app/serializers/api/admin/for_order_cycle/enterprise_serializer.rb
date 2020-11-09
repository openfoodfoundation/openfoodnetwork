# frozen_string_literal: true

require 'open_food_network/enterprise_issue_validator'

module Api
  module Admin
    module ForOrderCycle
      class EnterpriseSerializer < ActiveModel::Serializer
        attributes :id, :name, :managed,
                   :issues_summary_supplier, :issues_summary_distributor,
                   :is_primary_producer, :is_distributor, :sells

        def issues_summary_supplier
          issues =
            OpenFoodNetwork::EnterpriseIssueValidator.
              new(object).
              issues_summary(confirmation_only: true)

          if issues.nil? && products.empty?
            issues = I18n.t(:no_products)
          end
          issues
        end

        def issues_summary_distributor
          OpenFoodNetwork::EnterpriseIssueValidator.new(object).issues_summary
        end

        def managed
          Enterprise.managed_by(options[:spree_current_user]).include? object
        end

        private

        def products_scope
          products_relation = object.supplied_products
          if order_cycle.prefers_product_selection_from_coordinator_inventory_only?
            products_relation = products_relation.
              visible_for(order_cycle.coordinator)
          end
          products_relation
        end

        def products
          @products ||= products_scope
        end

        def order_cycle
          options[:order_cycle]
        end
      end
    end
  end
end
