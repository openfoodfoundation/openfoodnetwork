class Api::Admin::CalculatorSerializer < ActiveModel::Serializer
  attributes :name, :description

  delegate :name, to: :object

  delegate :description, to: :object
end
