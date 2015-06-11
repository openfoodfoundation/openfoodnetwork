class Api::Admin::IndexEnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :permalink, :is_primary_producer, :sells, :producer_profile_only, :owned

  def owned
    return true if options[:spree_current_user].admin?
    object.owner == options[:spree_current_user]
  end
end
