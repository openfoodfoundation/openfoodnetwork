class Api::StateSerializer < ActiveModel::Serializer
  attributes :id, :name, :abbr, :label

  def abbr
    object.abbr.upcase
  end

  def label 
	eval Spree::Config[:state_display]
  end

end