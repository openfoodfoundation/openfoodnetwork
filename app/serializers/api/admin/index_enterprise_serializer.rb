class Api::Admin::IndexEnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :permalink, :is_primary_producer, :sells, :producer_profile_only, :owned, :edit_path

  def owned
    return true if options[:spree_current_user].admin?
    object.owner == options[:spree_current_user]
  end

  def edit_path
    edit_admin_enterprise_path(object)
  end
end
