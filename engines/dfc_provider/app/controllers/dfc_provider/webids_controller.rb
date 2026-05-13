# frozen_string_literal: true

module DfcProvider
  # Publish WebIDs
  #
  # - https://docs.dfc-standard.org/dfc-standard-documentation/technical-specifications/data-storage-and-discovery#dfc-platform-webid
  class WebidsController < DfcProvider::ApplicationController
    skip_before_action :check_authorization, only: :show

    # Publish our platform WebID
    def show
      id = webid_url
      webid = {
        '@graph': [
          {
            '@id': id,
            '@type': "foaf:PersonalProfileDocument",
            'foaf:maker': "#{id}#me",
            'foaf:primaryTopic': "#{id}#me"
          },
          {
            '@id': "#{id}#me",
            '@type': [
              "dfc-t:Platform",
              "foaf:Agent"
            ],
            'foaf:name': t(:title),
            'dfc-t:supportedProtocolVersion': "2.0.0",
            'dfc-t:supportedOntologyVersion': "1.16.0",
            'dfc-t:hasIdentityService': "https://login.lescommuns.org/auth/realms/data-food-consortium"
          }
        ]
      }

      render(json: webid, content_type: "application/ld+json")
    end
  end
end
