# frozen_string_literal: true

module DfcProvider
  class PlatformsController < DfcProvider::ApplicationController
    # List of platform identifiers.
    #   local ID => semantic ID
    PLATFORM_IDS = {
      'cqcm-dev' => "https://api.proxy-dev.cqcm.startinblox.com/profile",
    }.freeze

    # DANGER!
    # This endpoint is open to CSRF attacks.
    # This is a temporary measure until the DFC Permissions module accesses
    # the API with a valid OIDC token to authenticate the user.
    skip_before_action :verify_authenticity_token

    before_action :check_enterprise

    def index
      render json: platforms
    end

    def show
      render json: platform(params[:id])
    end

    def update
      key = params[:id]
      requested_platform = JSON.parse(request.body.read)
      requested_scopes = requested_platform
        .dig("dfc-t:hasAssignedScopes", "@list")
        .pluck("@id")
        .map { |uri| uri[/[a-zA-Z]+$/] } # return last part like ReadEnterprise
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
      render json: platform(key)
    end

    private

    def platforms
      id = DfcProvider::Engine.routes.url_helpers.enterprise_platforms_url(current_enterprise.id)
      platforms = PLATFORM_IDS.keys.map(&method(:platform))

      {
        '@context': "https://cdn.startinblox.com/owl/context-bis.jsonld",
        '@id': id,
        'dfc-t:platforms': {
          '@type': "rdf:List",
          '@list': platforms,
        }
      }
    end

    def platform(key)
      {
        '@type': "dfc-t:Platform",
        '@id': PLATFORM_IDS[key],
        localId: key,
        'dfc-t:hasAssignedScopes': {
          '@type': "rdf:List",
          '@list': scopes(key),
        }
      }
    end

    def scopes(platform_id)
      granted_scopes(platform_id).map do |scope|
        {
          '@id': "https://example.com/scopes/#{scope}",
          '@type': "dfc-t:Scope",
          'dfc-t:scope': scope,
        }
      end
    end

    def granted_scopes(platform_id)
      DfcPermission.where(
        user: current_user,
        enterprise: current_enterprise,
        grantee: platform_id,
      ).pluck(:scope)
    end
  end
end
