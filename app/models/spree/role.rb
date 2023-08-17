# frozen_string_literal: true

module Spree
  class Role < ApplicationRecord
    has_many :role_users, dependent: :destroy
    has_many :users, through: :role_users, class_name: "Spree::User"
  end
end
