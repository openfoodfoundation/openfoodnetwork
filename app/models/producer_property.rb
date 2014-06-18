class ProducerProperty < ActiveRecord::Base
  belongs_to :property, class_name: 'Spree::Property'

  def property_name
    property.name if property
  end

  def property_name=(name)
    unless name.blank?
      self.property = Spree::Property.find_by_name(name) ||
        Spree::Property.create(name: name, presentation: name)
    end
  end
end
