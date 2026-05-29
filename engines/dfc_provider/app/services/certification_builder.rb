# frozen_string_literal: true

class CertificationBuilder < DfcBuilder
  def self.certification(property)
    DataFoodConsortium::Connector::Certification.new(
      "#certification-#{property.id}",
      name: property.name,
    )
  end
end
