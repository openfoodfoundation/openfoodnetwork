# frozen_string_literal: true

class ProducerProperty < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :producer, class_name: 'Enterprise', touch: true
  belongs_to :property, class_name: 'Spree::Property'

  default_scope { order("#{table_name}.position") }

  def property_name
    property&.name
  end

  def property_name=(name)
    return if name.blank?

    self.property = Spree::Property.find_by(name:) ||
                    Spree::Property.create(name:, presentation: name)
  end
end
