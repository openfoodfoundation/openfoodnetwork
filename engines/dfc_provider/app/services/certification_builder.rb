# frozen_string_literal: true

# We don't have certification data but we do have some self-declared
# properties. Examples of properties are:
#
# - Free Range
# - Organic - Certified
# - Vegetarian
#
class CertificationBuilder < DfcBuilder
  def self.certification(property)
    DataFoodConsortium::Connector::Certification.new(
      "#certification-#{property.id}",
      name: property.name,
    )
  end
end
