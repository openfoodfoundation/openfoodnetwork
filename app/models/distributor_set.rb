# Tableless model to handle updating multiple distributors at once from a
# single form. Used to update next_collection_at field for all distributors in
# admin backend.
class DistributorSet
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :distributors

  def initialize(attributes={})
    @distributors = Distributor.all

    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def distributors_attributes=(attributes)
    attributes.each do |k, attributes|
      # attributes == {:id => 123, :next_collection_at => '...'}
      d = @distributors.detect { |d| d.id.to_s == attributes[:id].to_s }
      d.assign_attributes(attributes.except(:id))
    end
  end

  def save
    distributors.all?(&:save)
  end

  def persisted?
    false
  end

end
