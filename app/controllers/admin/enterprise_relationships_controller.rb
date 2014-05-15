module Admin
  class EnterpriseRelationshipsController < ResourceController
    def index
      @enterprises = Enterprise.managed_by(spree_current_user).by_name
      @enterprise_relationships = EnterpriseRelationship.by_name
    end

    def create
      @enterprise_relationship = EnterpriseRelationship.new params[:enterprise_relationship]

      if @enterprise_relationship.save
        render partial: "admin/json/enterprise_relationship", locals: {enterprise_relationship: @enterprise_relationship}
      else
        render status: 413, json: @enterprise_relationship.errors
      end
    end
  end
end
