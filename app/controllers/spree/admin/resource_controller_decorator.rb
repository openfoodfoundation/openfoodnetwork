module AuthorizeOnLoadResource
  def load_resource
    super

    if member_action?
      # If we don't have access, clear the object
      unless can? action, @object
        instance_variable_set("@#{object_name}", nil)
      end

      authorize! action, @object
    end
  end
end

Spree::Admin::ResourceController.send(:prepend, AuthorizeOnLoadResource)
