# frozen_string_literal: true

module Admin
  class TagRulesController < Admin::ResourceController
    respond_to :json

    respond_override destroy: { json: {
      success: lambda { head :no_content }
    } }

    def new
      @index = params[:index]
      status = :ok
      if permitted_tag_rule_type.include?(params[:rule_type])
        @default_rule = "TagRule::#{params[:rule_type]}".constantize.new(is_default: true)
      else
        flash.now[:error] = t(".not_supported_type")
        status = :internal_server_error
      end

      respond_with do |format|
        return format.turbo_stream { render :new, status: }
      end
    end

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

    def permitted_tag_rule_type
      %w{FilterOrderCycles FilterPaymentMethods FilterProducts FilterShippingMethods}
    end
  end
end
