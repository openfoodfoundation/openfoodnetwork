# frozen_string_literal: true

module Api
  class EnterpriseThinSerializer < ActiveModel::Serializer
    attributes :name, :id, :active, :path, :visible

    has_one :address, serializer: Api::AddressSerializer

    def active
      enterprise.ready_for_checkout? && OrderCycle.active.with_distributor(enterprise).exists?
    end

    def path
      enterprise_shop_path(enterprise)
    end

    private

    def enterprise
      object
    end
  end
end
