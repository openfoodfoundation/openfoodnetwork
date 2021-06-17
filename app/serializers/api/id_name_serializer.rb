# frozen_string_literal: true

class Api::IdNameSerializer < ActiveModel::Serializer
  attributes :id, :name
end
