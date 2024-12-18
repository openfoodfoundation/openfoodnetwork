# frozen_string_literal: true

module Spree
  class Role < ApplicationRecord
    has_and_belongs_to_many :users, join_table: 'spree_roles_users',
                                    class_name: "Spree::User"

    # The only role we have at the moment:
    def self.admin
      Spree::Role.find_or_create_by(name: 'admin')
    end
  end
end
