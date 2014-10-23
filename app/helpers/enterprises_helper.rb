module EnterprisesHelper
  def current_distributor
    @current_distributor ||= current_order(false).andand.distributor
  end

  def available_shipping_methods
    current_distributor.shipping_methods.uniq
  end

  def managed_enterprises
    Enterprise.managed_by(spree_current_user)
  end
  
  def enterprises_options enterprises
    enterprises.map { |enterprise| [enterprise.name + ": " + enterprise.address.address1 + ", " + enterprise.address.city, enterprise.id.to_i] }
  end

  def enterprises_to_names(enterprises)
    enterprises.map(&:name).sort.join(', ')
  end

  def enterprise_type_name(enterprise)
    # TODO: When we can distinguish between profiles and producers that supply only (without
    #       their own store), include it here.
    # profile, supplier only, shopfront
    enterprise.sells == 'none' ? 'Profile' : 'Has Shopfront'
  end


  def enterprise_confirm_delete_message(enterprise)
    if enterprise.supplied_products.present?
      "This will also delete the #{pluralize enterprise.supplied_products.count, 'product'} that this enterprise supplies. Are you sure you want to continue?"
    else
      t(:are_you_sure)
    end
  end

  # Copied and modified from Spree's link_to_delete, which does not
  # allow customisation of the confirm message
  def link_to_delete_enterprise(enterprise)
    url = object_url(enterprise)
    name = t(:delete)
    options = {}
    options[:class] = "delete-resource"
    options[:data] = { :action => 'remove', :confirm => enterprise_confirm_delete_message(enterprise) }
    link_to_with_icon 'icon-trash', name, url, options
  end
end
