class Api::Admin::CalculatorSerializer < ActiveModel::Serializer
  attributes :name, :description

  def name
    object.name
  end

  def description
    object.description
  end
end
