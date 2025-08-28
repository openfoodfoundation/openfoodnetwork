# frozen_string_literal: true

module DfcProvider
  class PlatformsController < DfcProvider::ApplicationController
    # List of platform identifiers.
    #   local ID => semantic ID
    PLATFORM_IDS = {
      'cqcm-dev' => "https://api.proxy-stg.cqcm.startinblox.com/profile",
    }.freeze

    prepend_before_action :move_authenticity_token
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
        .map { |uri| uri[/[a-zA-Z]+\z/] } # return last part like ReadEnterprise
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
      platforms = available_platforms.map(&method(:platform))

      {
        '@context': "https://cdn.startinblox.com/owl/context-bis.jsonld",
        '@id': id,
        'dfc-t:platforms': {
          '@type': "rdf:List",
          '@list': platforms,
        }
      }
    end

    def available_platforms
      PLATFORM_IDS.keys.select(&method(:feature?))
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
          '@id': "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/scopes.rdf##{scope}",
          '@type': "dfc-t:Scope",
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

    # The DFC Permission Module is sending tokens in the Authorization header.
    # It assumes that it's an OIDC access token but we are passing the Rails
    # CSRF token to the component to allow POST request with cookie auth.
    def move_authenticity_token
      token = request.delete_header('HTTP_AUTHORIZATION').to_s.split.last
      request.headers['X-CSRF-Token'] = token if token
    end
  end
end
