# frozen_string_literal: false

class Invoice
  class CustomerSerializer < ActiveModel::Serializer
    attributes :code, :email
  end
end
