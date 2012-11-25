# Tableless model to handle updating multiple models at once from a single form
class ModelSet
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :collection

  def initialize(klass, collection, reject_if=nil, attributes={})
    @klass, @collection, @reject_if = klass, collection, reject_if

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def collection_attributes=(attributes)
    attributes.each do |k, attributes|
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
    @collection.map { |ef| ef.errors.full_messages }.flatten
  end

  def save
    collection.all?(&:save)
  end

  def persisted?
    false
  end

end
