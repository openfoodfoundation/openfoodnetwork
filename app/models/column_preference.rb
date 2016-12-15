require 'open_food_network/column_preference_defaults'

class ColumnPreference < ActiveRecord::Base
  extend OpenFoodNetwork::ColumnPreferenceDefaults

  # These are the attributes used to identify a preference
  attr_accessible :user_id, :action_name, :column_name

  # These are attributes that need to be mass assignable
  attr_accessible :name, :visible

  # Non-persisted attributes that only have one
  # setting (ie. the default) for a given column
  attr_accessor :name

  belongs_to :user, class_name: "Spree::User"

  validates :action_name, presence: true, inclusion: { in: proc { known_actions } }
  validates :column_name, presence: true, inclusion: { in: proc { |p| valid_columns_for(p.action_name) } }

  def self.for(user, action_name)
    stored_preferences = where(user_id: user.id, action_name: action_name)
    default_preferences = send("#{action_name}_columns")
    filter(default_preferences, user, action_name)
    default_preferences.each_with_object([]) do |(column_name, default_attributes), preferences|
      stored_preference = stored_preferences.find_by_column_name(column_name)
      if stored_preference
        stored_preference.assign_attributes(default_attributes.select{ |k,v| stored_preference[k].nil? })
        preferences << stored_preference
      else
        attributes = default_attributes.merge(user_id: user.id, action_name: action_name, column_name: column_name)
        preferences << ColumnPreference.new(attributes)
      end
    end
  end

  private

  def self.valid_columns_for(action_name)
    send("#{action_name}_columns").keys.map(&:to_s)
  end

  def self.known_actions
    OpenFoodNetwork::ColumnPreferenceDefaults.private_instance_methods
      .select{|m| m.to_s.end_with?("_columns")}.map{ |m| m.to_s.sub /_columns$/, ''}
  end

  # Arbitrary filtering of default_preferences
  def self.filter(default_preferences, user, action_name)
    if action_name == 'order_cycles_index'
      default_preferences.delete(:schedules) unless user.admin? || user.enterprises.where(enable_standing_orders: true).any?
    end
  end
end
