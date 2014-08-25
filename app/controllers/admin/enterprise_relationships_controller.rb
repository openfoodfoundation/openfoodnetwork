module Admin
  class EnterpriseRelationshipsController < ResourceController
    def index
      @my_enterprises = Enterprise.managed_by(spree_current_user).by_name
      @all_enterprises = Enterprise.by_name
      @enterprise_relationships = EnterpriseRelationship.by_name.involving_enterprises @my_enterprises
    end

    def create
      @enterprise_relationship = EnterpriseRelationship.new params[:enterprise_relationship]

      if @enterprise_relationship.save
        render text: Api::Admin::EnterpriseRelationshipSerializer.new(@enterprise_relationship).to_json
      else
        render status: 400, json: {errors: @enterprise_relationship.errors.full_messages.join(', ')}
      end
    end

    def destroy
      @enterprise_relationship = EnterpriseRelationship.find params[:id]
      @enterprise_relationship.destroy
      render nothing: true
    end
  end
end
