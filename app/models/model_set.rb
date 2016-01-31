# Tableless model to handle updating multiple models at once from a single form
class ModelSet
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :collection

  def initialize(klass, collection, attributes={}, reject_if=nil, delete_if=nil)
    @klass, @collection, @reject_if, @delete_if = klass, collection, reject_if, delete_if

    # Set here first, to ensure that we apply collection_attributes to the right collection
    @collection = attributes[:collection] if attributes[:collection]

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def collection_attributes=(collection_attributes)
    collection_attributes.each do |k, attributes|
      # attributes == {:id => 123, :next_collection_at => '...'}
      e = @collection.detect { |e| e.id.to_s == attributes[:id].to_s && !e.id.nil? }
      if e.nil?
        @collection << @klass.new(attributes) unless @reject_if.andand.call(attributes)
      else
        e.assign_attributes(attributes.except(:id))
      end
    end
  end

  def errors
    errors = ActiveModel::Errors.new self
    full_messages = @collection.map { |ef| ef.errors.full_messages }.flatten
    full_messages.each { |fm| errors.add(:base, fm) }
    errors
  end

  def save
    collection_to_delete.each &:destroy
    collection_to_keep.all? &:save
  end

  def collection_to_delete
    # Remove all elements to be deleted from collection and return them
    # Allows us to render @model_set.collection without deleted elements
    deleted = []
    collection.delete_if { |e| deleted << e if @delete_if.andand.call(e.attributes) }
    deleted
  end

  def collection_to_keep
    collection.reject { |e| @delete_if.andand.call(e.attributes) }
  end

  def persisted?
    false
  end
end
