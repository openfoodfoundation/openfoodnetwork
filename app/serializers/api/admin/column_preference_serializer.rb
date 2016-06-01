class Api::Admin::ColumnPreferenceSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :action_name, :column_name, :name, :visible
end
