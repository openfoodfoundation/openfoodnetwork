# frozen_string_literal: false

class Invoice
  class UserSerializer < ActiveModel::Serializer
    attributes :email
  end
end
