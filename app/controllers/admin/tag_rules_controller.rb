# frozen_string_literal: true

module Admin
  class TagRulesController < Spree::Admin::BaseController
    respond_to :json

    def new
      @index = params[:index]
      @div_id = params[:div_id]
      is_default = params[:is_default]
      @customer_tags = params[:customer_tags]

      status = :ok
      if permitted_tag_rule_type.include?(params[:rule_type])
        @default_rule = "TagRule::#{params[:rule_type]}".constantize.new(is_default:)
      else
        flash.now[:error] = t(".not_supported_type")
        status = :internal_server_error
      end

      respond_with do |format|
        format.turbo_stream { render :new, status: }
      end
    end

    def destroy
      @rule = TagRule.find(params[:id])
      @index = params[:index]
      authorize! :destroy, @rule

      status = :ok
      if @rule.destroy
        flash[:success] = I18n.t(:successfully_removed, resource: "Tag Rule")
      else
        flash.now[:error] = t(".destroy_error")
        status = :internal_server_error
      end

      respond_to do |format|
        format.turbo_stream { render :destroy, status: }
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

    def model_class
      TagRule
    end

    def permitted_tag_rule_type
      %w{FilterOrderCycles FilterPaymentMethods FilterProducts FilterShippingMethods}
    end
  end
end
