# Tableless model to handle updating multiple enterprises at once from a
# single form. Used to update next_collection_at field for all distributors in
# admin backend.
class EnterpriseSet
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :enterprises

  def initialize(attributes={})
    @enterprises = Enterprise.all

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def enterprises_attributes=(attributes)
    attributes.each do |k, attributes|
      # attributes == {:id => 123, :next_collection_at => '...'}
      e = @enterprises.detect { |e| e.id.to_s == attributes[:id].to_s }
      e.assign_attributes(attributes.except(:id))
    end
  end

  def save
    enterprises.all?(&:save)
  end

  def persisted?
    false
  end

end
