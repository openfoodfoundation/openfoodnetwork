# frozen_string_literal: true

module Spree
  class RoleUser < ApplicationRecord
    self.table_name = "spree_roles_users"

    belongs_to :role, class_name: 'Spree::Role'
    belongs_to :user, class_name: 'Spree::User'
  end
end
