# frozen_string_literal: true

module Api
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :email
  end
end
