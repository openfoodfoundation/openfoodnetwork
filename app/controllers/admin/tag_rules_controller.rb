# frozen_string_literal: true

module Admin
  class TagRulesController < Admin::ResourceController
    respond_to :json

    respond_override destroy: { json: {
      success: lambda { render body: nil, status: :no_content }
    } }

    def map_by_tag
      respond_to do |format|
        format.json do
          serializer = ActiveModel::ArraySerializer.new(collection)
          render json: serializer.to_json
        end
      end
    end

    private

    def collection_actions
      [:index, :map_by_tag]
    end

    def collection
      case action
      when :map_by_tag
        TagRule.mapping_for(enterprises).values
      else
        TagRule.for(enterprises.pluck(&:id))
      end
    end

    def enterprises
      if params[:enterprise_id]
        Enterprise.managed_by(spree_current_user).where(id: params[:enterprise_id])
      else
        Enterprise.managed_by(spree_current_user)
      end
    end
  end
end
