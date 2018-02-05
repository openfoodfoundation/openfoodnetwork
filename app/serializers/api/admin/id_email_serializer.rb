module Api
  module Admin
    class IdEmailSerializer < ActiveModel::Serializer
      attributes :id, :email
    end
  end
end
