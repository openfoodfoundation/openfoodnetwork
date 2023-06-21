# frozen_string_literal: true

module Admin
  class EnterpriseRelationshipsController < Admin::ResourceController
    def index
      @my_enterprises = Enterprise.
        includes(:shipping_methods, :payment_methods).
        managed_by(spree_current_user).by_name
      @all_enterprises = Enterprise.includes(:shipping_methods, :payment_methods).by_name
      @enterprise_relationships = EnterpriseRelationship.
        includes(:parent, :child, :permissions).
        by_name.involving_enterprises @my_enterprises
    end

    def create
      @enterprise_relationship = EnterpriseRelationship.new enterprise_relationship_params

      if @enterprise_relationship.save
        render plain: Api::Admin::EnterpriseRelationshipSerializer
          .new(@enterprise_relationship).to_json
      else
        render status: :bad_request,
               json: { errors: @enterprise_relationship.errors.full_messages.join(', ') }
      end
    end

    def destroy
      @enterprise_relationship = EnterpriseRelationship.find params[:id]
      @enterprise_relationship.destroy
      render body: nil
    end

    private

    def enterprise_relationship_params
      params.require(:enterprise_relationship).permit(:parent_id, :child_id, permissions_list: [])
    end
  end
end
