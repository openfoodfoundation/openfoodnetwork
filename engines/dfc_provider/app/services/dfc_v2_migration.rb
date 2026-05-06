# frozen_string_literal: true

# Transform DFC v1 data to DFC v2.
module DfcV2Migration
  def self.up(enterprises)
    enterprises.map do |enterprise|
      DataFoodConsortium::Connector::Organization.new(
        enterprise.semanticId,
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
      )
    end
  end
end
