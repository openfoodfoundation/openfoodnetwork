# frozen_string_literal: true

class EnterpriseRelationshipPermission < ApplicationRecord
  default_scope { order('name') }
end
