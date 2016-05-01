module Admin
  class TagsController < Spree::Admin::BaseController
    respond_to :json

    def index
      respond_to do |format|
        format.json do
          serialiser = ActiveModel::ArraySerializer.new(tags_of_enterprise)
          render json: serialiser.to_json
        end
      end
    end

    private

    def enterprise
      Enterprise.managed_by(spree_current_user).find_by_id(params[:enterprise_id])
    end

    def tags_of_enterprise
      return [] unless enterprise
      tag_rule_map = enterprise.rules_per_tag
      tag_rule_map.keys.map do |tag|
        { text: tag, rules: tag_rule_map[tag] }
      end
    end
  end
end
