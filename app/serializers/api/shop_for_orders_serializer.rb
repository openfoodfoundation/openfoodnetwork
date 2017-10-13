module Api
  class ShopForOrdersSerializer < ActiveModel::Serializer
    attributes :id, :name, :hash, :logo

    def hash
      object.to_param
    end

    def logo
      object.logo(:small) if object.logo?
    end
  end
end
