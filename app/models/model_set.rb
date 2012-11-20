# Tableless model to handle updating multiple models at once from a single form
class ModelSet
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :collection

  def initialize(collection, attributes={})
    @collection = collection

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def collection_attributes=(attributes)
    attributes.each do |k, attributes|
      # attributes == {:id => 123, :next_collection_at => '...'}
      e = @collection.detect { |e| e.id.to_s == attributes[:id].to_s }
      e.assign_attributes(attributes.except(:id))
    end
  end

  def save
    collection.all?(&:save)
  end

  def persisted?
    false
  end

end
