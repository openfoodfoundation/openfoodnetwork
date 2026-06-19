# frozen_string_literal: true

# Transform DFC v1 data to DFC v2.
module DfcV2Migration
  def self.up(*objects)
    objects.map do |object|
      case object
      when DataFoodConsortium::ConnectorV1::Enterprise
        up_enterprise(object)
      when DataFoodConsortium::ConnectorV1::Person
        up_person(object)
      when VirtualAssembly::Semantizer::SemanticObject
        up_generic(object)
      else
        # Not sure what this is but we can't migrate it and leave it as is.
        object
      end
    end
  end

  def self.up_enterprise(enterprise)
    # We introduce new ids for our enterprises on the new version of the API.
    # This is not strictly necessary but will make the API more consistent
    # in the future. Since DFC v2 is a big breaking change, we may use that
    # to ignore any requirement to be backwards compatible here.
    #
    # If an old integration upgrades to DFC v2, they have to update their
    # internally stored ids for enterprises.
    id = enterprise.semanticId.sub("/api/dfc/enterprises/", "/api/dfc/organizations/")

    DataFoodConsortium::Connector::Organization.new(
      id,
      name: enterprise.name,
      description: enterprise.description,
      vatNumber: enterprise.vatNumber,
      suppliedProducts: enterprise.suppliedProducts,
      catalogItems: enterprise.catalogItems,
      emails: enterprise.emails,
      localizations: enterprise.localizations,
      phoneNumbers: enterprise.phoneNumbers,
      socialMedias: enterprise.socialMedias,
      logo: enterprise.logo,
      mainContact: enterprise.mainContact,
      websites: enterprise.websites,
      certifications: enterprise.certifications,
    )
  end

  def self.up_person(person)
    id = person.semanticId.sub("/api/dfc/enterprises/", "/api/dfc/organizations/")
    up_generic(person, id)
  end

  def self.up_generic(object, id = object.semanticId, **)
    v1_class = object.class.ancestors.find do |ancestor|
      ancestor.module_parent == DataFoodConsortium::ConnectorV1
    end

    # It may be DfcV2 already, or something unknown.
    return object if v1_class.nil?

    class_name = v1_class.name.demodulize
    v2_class = DataFoodConsortium::Connector.const_get(class_name)

    v2_class.new(id, **).tap do |o|
      o.semanticProperties.each do |property|
        next if property.value.present?

        property.value = object.semanticPropertyValue(property.name)
      end
    end
  end
end
