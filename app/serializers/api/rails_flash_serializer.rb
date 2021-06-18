# frozen_string_literal: true

module Api
  class RailsFlashSerializer < ActiveModel::Serializer
    attributes :info, :success, :error, :notice

    delegate :info, :success, :error, :notice, to: :object
  end
end
