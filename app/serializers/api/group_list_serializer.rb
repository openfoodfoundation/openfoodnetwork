# frozen_string_literal: true

module Api
  class GroupListSerializer < ActiveModel::Serializer
    attributes :id, :name, :permalink, :email, :website, :facebook, :instagram,
               :linkedin, :twitter, :enterprises, :state, :address_id

    def state
      object.address.state.abbr
    end

    def enterprises
      ActiveModel::ArraySerializer.new(
        object.enterprises, each_serializer: Api::EnterpriseThinSerializer
      )
    end
  end
end
