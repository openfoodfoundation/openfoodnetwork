# frozen_string_literal: true

module OpenFoodNetwork
  class Feature
    def initialize(users = [])
      @users = users
    end

    def enabled?(user)
      users.include?(user.email)
    end

    private

    attr_reader :users
  end
end
