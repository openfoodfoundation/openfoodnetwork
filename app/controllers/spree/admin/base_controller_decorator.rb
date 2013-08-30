Spree::Admin::BaseController.class_eval do
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
end