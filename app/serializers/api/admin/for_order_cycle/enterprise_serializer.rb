require 'open_food_network/enterprise_issue_validator'

class Api::Admin::ForOrderCycle::EnterpriseSerializer < ActiveModel::Serializer
  attributes :id, :name, :managed, :supplied_products
  attributes :issues_summary_supplier, :issues_summary_distributor
  attributes :is_primary_producer, :is_distributor, :sells

  def issues_summary_supplier
    issues = OpenFoodNetwork::EnterpriseIssueValidator.new(object).issues_summary confirmation_only: true
    if issues.nil? && products.empty?
      issues = "no products in inventory"
    end
    issues
  end

  def issues_summary_distributor
    OpenFoodNetwork::EnterpriseIssueValidator.new(object).issues_summary
  end

  def managed
    Enterprise.managed_by(options[:spree_current_user]).include? object
  end

  def supplied_products
    serializer = Api::Admin::ForOrderCycle::SuppliedProductSerializer
    ActiveModel::ArraySerializer.new(products, each_serializer: serializer, order_cycle: order_cycle)
  end

  private

  def products
    return @products unless @products.nil?
    @products = if order_cycle.prefers_product_selection_from_coordinator_inventory_only?
      object.supplied_products.not_deleted.visible_for(order_cycle.coordinator)
    else
      object.supplied_products.not_deleted
    end
  end

  def order_cycle
    options[:order_cycle]
  end
end
