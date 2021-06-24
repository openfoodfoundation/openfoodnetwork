# frozen_string_literal: true

module Api
  class TaxonJstreeSerializer < ActiveModel::Serializer
    attributes :data, :state
    has_one :attr, serializer: TaxonJstreeAttributeSerializer

    def data
      object.name
    end

    def attr
      object
    end

    def state
      "closed"
    end
  end
end
