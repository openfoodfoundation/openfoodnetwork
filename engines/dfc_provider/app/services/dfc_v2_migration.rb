# frozen_string_literal: true

# Transform DFC v1 data to DFC v2.
module DfcV2Migration
  def self.up(enterprises)
    enterprises.map do |enterprise|
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
  end
end
