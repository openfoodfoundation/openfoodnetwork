require 'spree/core/controller_helpers/respond_with_decorator'

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
      redirect_to root_path(anchor: "login?after_login=#{request.env.fullpath}")
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

  def html_request?
    request.format.html?
  end

  def json_request?
    request.format.json?
  end

  def render_as_json(data, options={})
    ams_prefix = options.delete :ams_prefix
    if [Array, ActiveRecord::Relation].include? data.class
      render options.merge(json: data, each_serializer: serializer(ams_prefix))
    else
      render options.merge(json: data, serializer: serializer(ams_prefix))
    end
  end

  def serializer(ams_prefix)
    if ams_prefix.nil? || ams_prefix_whitelist.include?(ams_prefix.to_sym)
      prefix = ams_prefix.andand.classify || ""
      name = controller_name.classify
      "Api::Admin::#{prefix}#{name}Serializer".constantize
    else
      raise "Suffix '#{ams_prefix}' not found in ams_prefix_whitelist for #{self.class.name}."
    end
  end
end
