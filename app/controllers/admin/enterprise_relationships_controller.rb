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
      # Given that we get an empty object when checking for :create ability in
      # Admin::ResourceController, we can't check the user manages the parent enterprise with
      # an ability. So we do it manually here.
      unless can_grant_permission?
        raise CanCan::AccessDenied
      end

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

    def can_grant_permission?
      OpenFoodNetwork::Permissions.new(spree_current_user).managed_enterprises.where(
        id: enterprise_relationship_params[:parent_id]
      ).exists?
    end
  end
end
