module Api
  class CustomerSerializer < ActiveModel::Serializer
    attributes :id, :enterprise_id, :name, :code, :email, :allow_charges
  end
end
