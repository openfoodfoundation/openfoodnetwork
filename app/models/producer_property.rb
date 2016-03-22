class ProducerProperty < ActiveRecord::Base
  belongs_to :producer, class_name: 'Enterprise'
  belongs_to :property, class_name: 'Spree::Property'

  default_scope order("#{self.table_name}.position")

  after_save :refresh_products_cache
  after_destroy :refresh_products_cache_from_destroy


  def property_name
    property.name if property
  end

  def property_name=(name)
    unless name.blank?
      self.property = Spree::Property.find_by_name(name) ||
        Spree::Property.create(name: name, presentation: name)
    end
  end


  private

  def refresh_products_cache
    OpenFoodNetwork::ProductsCache.producer_property_changed self
  end

  def refresh_products_cache_from_destroy
    OpenFoodNetwork::ProductsCache.producer_property_destroyed self
  end

end
