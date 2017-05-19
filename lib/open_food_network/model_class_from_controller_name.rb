module OpenFoodNetwork
  module ModelClassFromControllerName
    # Equivalent to CanCan's "authorize_resource :class => false" (see https://github.com/ryanb/cancan/blob/master/lib/cancan/controller_resource.rb#L146)
    def model_class
      self.class.to_s.sub("Controller", "").underscore.split('/').last.singularize.to_sym
    end
  end
end
