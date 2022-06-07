# frozen_string_literal: true

module Api
  class ShopForOrdersSerializer < ActiveModel::Serializer
    attributes :id, :name, :hash, :logo

    def hash
      object.to_param
    end

    def logo
      object.logo_url(:small)
    end
  end
end
