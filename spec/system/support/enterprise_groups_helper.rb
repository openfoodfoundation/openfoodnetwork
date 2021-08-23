# frozen_string_literal: true

module OpenFoodNetwork
  module EnterpriseGroupsHelper
    def create_enterprise_group_for(distributor)
      create(:enterprise_group, on_front_page: true, enterprises: [distributor])
    end
  end
end
