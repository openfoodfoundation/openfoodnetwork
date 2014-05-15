module Admin
  class EnterpriseRelationshipsController < ResourceController
    def index
      @enterprise_relationships = EnterpriseRelationship.by_name
    end
  end
end
