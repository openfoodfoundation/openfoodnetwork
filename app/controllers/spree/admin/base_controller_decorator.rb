Spree::Admin::BaseController.class_eval do
  before_filter :warn_invalid_order_cycles

  # Warn the user when they have an active order cycle with hubs that are not ready
  # for checkout (ie. does not have valid shipping and payment methods).
  def warn_invalid_order_cycles
    distributors = active_distributors_not_ready_for_checkout

    if distributors.any? && flash[:notice].nil?
      flash[:notice] = active_distributors_not_ready_for_checkout_message(distributors)
    end
  end

  # Override Spree method
  # It's a shame Spree doesn't just let CanCan handle this in it's own way
  def authorize_admin
    if respond_to?(:model_class, true) && model_class
      record = model_class
    else
      # this line changed to allow specificity for each non-resource controller (to be consistent with "authorize_resource :class => false", see https://github.com/ryanb/cancan/blob/60cf6a67ef59c0c9b63bc27ea0101125c4193ea6/lib/cancan/controller_resource.rb#L146)
      record = self.class.to_s.sub("Controller", "").underscore.split('/').last.singularize.to_sym
    end
    authorize! :admin, record
    authorize! action, record
  end

  # This is in Spree::Core::ControllerHelpers::Auth
  # But you can't easily reopen modules in Ruby
  def unauthorized
    if try_spree_current_user
      flash[:error] = t(:authorization_failure)
      redirect_to '/unauthorized'
    else
      store_location
      redirect_to root_path(anchor: "login?after_login=#{request.env['PATH_INFO']}")
    end
  end


  private

  def active_distributors_not_ready_for_checkout
    ocs = OrderCycle.managed_by(spree_current_user).active
    distributors = ocs.map(&:distributors).flatten.uniq
    Enterprise.where('id IN (?)', distributors).not_ready_for_checkout
  end

  def active_distributors_not_ready_for_checkout_message(distributors)
    distributor_names = distributors.map(&:name).join ', '

    if distributors.count > 1
      "The hubs #{distributor_names} are listed in an active order cycle, " +
        "but do not have valid shipping and payment methods. " +
        "Until you set these up, customers will not be able to shop at these hubs."
    else
      "The hub #{distributor_names} is listed in an active order cycle, " +
        "but does not have valid shipping and payment methods. " +
        "Until you set these up, customers will not be able to shop at this hub."
    end
  end
end
