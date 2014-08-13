module Admin
  class EnterpriseRolesController < ResourceController
    def index
      @enterprise_roles = EnterpriseRole.by_user_email
    end
  end
end
