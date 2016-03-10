module Admin
  class InventoryItemsController < ResourceController

    respond_to :json

    respond_override update: { json: {
      success: lambda { render_as_json @inventory_item },
      failure: lambda { render json: { errors: @inventory_item.errors.full_messages }, status: :unprocessable_entity }
    } }

    respond_override create: { json: {
      success: lambda { render_as_json @inventory_item },
      failure: lambda { render json: { errors: @inventory_item.errors.full_messages }, status: :unprocessable_entity }
    } }

    private

    # Overriding Spree method to load data from params here so that
    # we can authorise #create using an object with required attributes
    def build_resource
      if parent_data.present?
        parent.send(controller_name).build
      else
        model_class.new(params[object_name]) # This line changed
      end
    end
  end
end
