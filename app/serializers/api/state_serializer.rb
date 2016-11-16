class Api::StateSerializer < ActiveModel::Serializer
  attributes :id, :name, :abbr, :label

  def abbr
    object.abbr.upcase
  end

  def label 
	eval I18n.t("registration_detail_state_label")
  end

end