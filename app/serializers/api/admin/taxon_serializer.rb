# frozen_string_literal: true

module Api
  module Admin
    class TaxonSerializer < ActiveModel::Serializer
      attributes :id, :name, :pretty_name
    end
  end
end
