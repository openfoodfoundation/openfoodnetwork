module Admin
  class ResourceController < Spree::Admin::ResourceController
    def model_class
      "#{controller_name.classify}".constantize
    end

    # URL helpers
    def new_object_url(options = {})
      if parent_data.present?
        main_app.new_polymorphic_url([:admin, parent, model_class], options)
      else
        main_app.new_polymorphic_url([:admin, model_class], options)
      end
    end

    def edit_object_url(object, options = {})
      if parent_data.present?
        main_app.send "edit_admin_#{model_name}_#{object_name}_url", parent, object, options
      else
        main_app.send "edit_admin_#{object_name}_url", object, options
      end
    end

    def object_url(object = nil, options = {})
      target = object ? object : @object
      if parent_data.present?
        main_app.send "admin_#{model_name}_#{object_name}_url", parent, target, options
      else
        main_app.send "admin_#{object_name}_url", target, options
      end
    end

    def collection_url(options = {})
      if parent_data.present?
        main_app.polymorphic_url([:admin, parent, model_class], options)
      else
        main_app.polymorphic_url([:admin, model_class], options)
      end
    end
  end
end
