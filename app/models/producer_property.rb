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
    if name.present?
      self.property = Spree::Property.find_by(name: name) ||
                      Spree::Property.create(name: name, presentation: name)
    end
  end
end
