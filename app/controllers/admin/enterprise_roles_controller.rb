# frozen_string_literal: true

module Admin
  class EnterpriseRolesController < Admin::ResourceController
    def index
      @enterprise_roles, @users, @all_enterprises = Admin::EnterpriseRolesQuery.query
      @my_enterprises = @all_enterprises
    end

    def create
      @enterprise_role = EnterpriseRole.new enterprise_role_params

      if @enterprise_role.save
        render plain: Api::Admin::EnterpriseRoleSerializer.new(@enterprise_role).to_json

      else
        render status: :bad_request,
               json: { errors: @enterprise_role.errors.full_messages.join(', ') }
      end
    end

    def destroy
      @enterprise_role = EnterpriseRole.find params[:id]
      @enterprise_role.destroy
      render body: nil
    end

    private

    def enterprise_role_params
      params.require(:enterprise_role).permit(:user_id, :enterprise_id)
    end
  end
end
