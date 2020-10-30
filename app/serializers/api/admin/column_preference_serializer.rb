# frozen_string_literal: true

module Api
  module Admin
    class ColumnPreferenceSerializer < ActiveModel::Serializer
      attributes :id, :user_id, :action_name, :column_name, :name, :visible
    end
  end
end
