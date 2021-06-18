# frozen_string_literal: true

class Api::CountrySerializer < ActiveModel::Serializer
  attributes :id, :name, :states

  has_many :states, serializer: Api::StateSerializer
end
