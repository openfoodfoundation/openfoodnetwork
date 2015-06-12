class Api::Admin::IndexEnterpriseSerializer < ActiveModel::Serializer
  attributes :name, :id, :permalink, :is_primary_producer, :sells, :producer_profile_only, :owned, :edit_path

  attributes :issues, :warnings

  def owned
    return true if options[:spree_current_user].admin?
    object.owner == options[:spree_current_user]
  end

  def edit_path
    edit_admin_enterprise_path(object)
  end

  def shipping_methods_ok?
    return true unless object.is_distributor
    object.shipping_methods.any?
  end

  def payment_methods_ok?
    return true unless object.is_distributor
    object.payment_methods.any?
  end

  def issues
    [
      {
        resolved: shipping_methods_ok?,
        description: "#{object.name} currently has no shipping methods.",
        link: "<a class='button fullwidth' href='#{spree.new_admin_shipping_method_path}'>Create New</a>"
      },
      {
        resolved: payment_methods_ok?,
        description: "#{object.name} currently has no payment methods.",
        link: "<a class='button fullwidth' href='#{spree.new_admin_payment_method_path}'>Create New</a>"
      },
      {
        resolved: object.confirmed?,
        description: "Email confirmation is pending. We've sent a confirmation email to #{object.email}.",
        link: "<a class='button fullwidth' href='#{enterprise_confirmation_path(enterprise: { id: object.id, email: object.email } )}' method='post'>Resend Email</a>"
      }
    ]
  end

  def warnings
    [
      {
        resolved: object.visible,
        description: "#{object.name} is not visible and so cannot be found on the map or in searches",
        link: "<a class='button fullwidth' href='#{edit_admin_enterprise_path(object)}'>Edit</a>"
      }
    ]
  end
end
