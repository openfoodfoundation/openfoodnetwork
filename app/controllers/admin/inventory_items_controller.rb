# frozen_string_literal: true

module Admin
  class InventoryItemsController < Admin::ResourceController
    respond_to :json

    respond_override update: { json: {
      success: lambda { render_as_json @inventory_item },
      failure: lambda {
                 render json: { errors: @inventory_item.errors.full_messages },
                        status: :unprocessable_entity
               }
    } }

    respond_override create: { json: {
      success: lambda { render_as_json @inventory_item },
      failure: lambda {
                 render json: { errors: @inventory_item.errors.full_messages },
                        status: :unprocessable_entity
               }
    } }

    private

    # Overriding resource_controller method to load data from params here so that
    # we can authorise #create using an object with required attributes
    def build_resource
      model_class.new(permitted_resource_params)
    end

    def permitted_resource_params
      params.require(:inventory_item).permit(:enterprise_id, :variant_id, :visible)
    end
  end
end
