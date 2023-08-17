# frozen_string_literal: true

class EnterpriseGroupEnterprise < ApplicationRecord
  self.table_name = "enterprise_groups_enterprises"

  belongs_to :enterprise_group, class_name: 'EnterpriseGroup'
  belongs_to :enterprise
end
