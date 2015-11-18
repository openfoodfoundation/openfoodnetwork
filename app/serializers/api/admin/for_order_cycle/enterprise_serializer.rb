require 'open_food_network/enterprise_issue_validator'

class Api::Admin::ForOrderCycle::EnterpriseSerializer < ActiveModel::Serializer
  attributes :id, :name, :managed, :supplied_products
  attributes :issues_summary_supplier, :issues_summary_distributor
  attributes :is_primary_producer, :is_distributor, :sells

  def issues_summary_supplier
    OpenFoodNetwork::EnterpriseIssueValidator.new(object).issues_summary confirmation_only: true
  end

  def issues_summary_distributor
    OpenFoodNetwork::EnterpriseIssueValidator.new(object).issues_summary
  end

  def managed
    Enterprise.managed_by(options[:spree_current_user]).include? object
  end

  def supplied_products
    objects = object.supplied_products.not_deleted
    serializer = Api::Admin::ForOrderCycle::SuppliedProductSerializer
    ActiveModel::ArraySerializer.new(objects, each_serializer: serializer)
  end
end
