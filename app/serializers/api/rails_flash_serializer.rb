class Api::RailsFlashSerializer < ActiveModel::Serializer
  attributes :info, :success, :error, :notice
end
