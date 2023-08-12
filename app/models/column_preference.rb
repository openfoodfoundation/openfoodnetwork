# frozen_string_literal: true

require 'open_food_network/column_preference_defaults'

class ColumnPreference < ApplicationRecord
  extend OpenFoodNetwork::ColumnPreferenceDefaults

  # Non-persisted attributes that only have one
  # setting (ie. the default) for a given column
  attr_accessor :name

  belongs_to :user, class_name: "Spree::User"

  validates :action_name, presence: true, inclusion: { in: proc { known_actions } }
  validates :column_name, presence: true, inclusion: { in: proc { |p|
                                                             valid_columns_for(p.action_name)
                                                           } }

  def self.for(user, action_name)
    stored_preferences = where(user_id: user.id, action_name: action_name)
    default_preferences = __send__("#{action_name}_columns")
    filter(default_preferences, user, action_name)
    default_preferences.each_with_object([]) do |(column_name, default_attributes), preferences|
      stored_preference = stored_preferences.find_by(column_name: column_name)
      if stored_preference
        stored_preference.assign_attributes(default_attributes.select{ |k, _v|
                                              stored_preference[k].nil?
                                            } )
        preferences << stored_preference
      else
        attributes = default_attributes.merge(user_id: user.id, action_name: action_name,
                                              column_name: column_name)
        preferences << ColumnPreference.new(attributes)
      end
    end
  end

  def self.valid_columns_for(action_name)
    __send__("#{action_name}_columns").keys.map(&:to_s)
  end

  def self.known_actions
    OpenFoodNetwork::ColumnPreferenceDefaults.private_instance_methods
      .select{ |m| m.to_s.end_with?("_columns") }.map{ |m| m.to_s.sub /_columns$/, '' }
  end

  # Arbitrary filtering of default_preferences
  def self.filter(default_preferences, user, action_name)
    return unless action_name == 'order_cycles_index'

    return if user.admin? || user.enterprises.where(enable_subscriptions: true).any?

    default_preferences.delete(:schedules)
  end
end
