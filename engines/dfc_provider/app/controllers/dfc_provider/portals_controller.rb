# frozen_string_literal: true

module DfcProvider
  class PortalsController < DfcProvider::ApplicationController
    PORTALS = {
      '682afcc4966dbb3aa7464d56' => {
        '@id': "https://waterlooregionfood.ca/portal/profile",
        description: "A super duper portal for the waterloo region",
        termsandconditions: "https://waterlooregionfood.ca/terms-and-conditions",
        title: "Waterloo Region Food Portal",
      },
      '682b2e2b031c28f69cda1645' => {
        '@id': "https://anotherplatform.ca/portal/profile",
        description: "A super duper portal for the waterloo region",
        termsandconditions: "https://anotherplatform.ca/terms-and-conditions",
        title: "anotherplatform Portal",
      },
    }.freeze

    # DANGER!
    # This endpoint is open to CSRF attacks.
    # This is a temporary measure until the DFC Permissions module accesses
    # the API with a valid OIDC token to authenticate the user.
    skip_before_action :verify_authenticity_token

    before_action :check_enterprise

    def index
      render json: portals
    end

    def update
      key = params[:id]
      requested_portal = JSON.parse(request.body.read)
      requested_scopes = requested_portal
        .dig("dfc-t:hasAssignedScopes", "@list")
        .pluck("dfc-t:scope")
      current_scopes = granted_scopes(key)
      scopes_to_delete = current_scopes - requested_scopes
      scopes_to_create = requested_scopes - current_scopes

      DfcPermission.where(
        user: current_user,
        enterprise: current_enterprise,
        scope: scopes_to_delete,
        grantee: key,
      ).delete_all

      scopes_to_create.each do |scope|
        DfcPermission.create!(
          user: current_user,
          enterprise: current_enterprise,
          scope:,
          grantee: key,
        )
      end
      render json: portal(key)
    end

    private

    def portals
      id = DfcProvider::Engine.routes.url_helpers.enterprise_portals_url(current_enterprise.id)
      portals = PORTALS.keys.map(&method(:portal))

      {
        '@context': "https://cdn.startinblox.com/owl/context-bis.jsonld",
        '@id': id,
        'dfc-t:platforms': {
          '@type': "rdf:List",
          '@list': portals,
        }
      }
    end

    def portal(key)
      {
        '@type': "dfc-t:Platform",
        _id: { '$oid': key },
        'dfc-t:hasAssignedScopes': {
          '@type': "rdf:List",
          '@list': scopes(key),
        }
      }.merge(PORTALS[key])
    end

    def scopes(portal_id)
      granted_scopes(portal_id).map do |scope|
        {
          '@id': "##{scope}",
          '@type': "dfc-t:Scope",
          'dfc-t:scope': scope,
        }
      end
    end

    def granted_scopes(portal_id)
      DfcPermission.where(
        user: current_user,
        enterprise: current_enterprise,
        grantee: portal_id,
      ).pluck(:scope)
    end
  end
end
