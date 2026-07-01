# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module DfcProvider
  class ApplicationController < ActionController::Base
    class Unauthorized < StandardError; end

    include ActiveStorage::SetCurrent

    protect_from_forgery with: :null_session

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from CanCan::AccessDenied, with: :unauthorized
    rescue_from Unauthorized, with: :unauthorized

    before_action :check_authorization

    respond_to :json

    private

    def require_permission(scope)
      return if current_user.is_a? Spree::User
      return if current_user.permissions(scope).where(enterprise: current_enterprise).exists?

      raise Unauthorized
    end

    def check_authorization
      unauthorized if current_user.nil?
    end

    def check_enterprise
      return if current_enterprise.present?

      not_found
    end

    def current_enterprise
      @current_enterprise ||=
        case params[enterprise_id_param_name]
        when 'default'
          current_user.enterprises.first!
        else
          current_user.enterprises.find(params[enterprise_id_param_name])
        end
    end

    def enterprise_id_param_name
      :enterprise_id
    end

    def current_user
      @current_user ||= authorization_control.user
    end

    def authorization_control
      AuthorizationControl.new(request)
    end

    def not_found
      head :not_found
    end

    def unauthorized
      head :unauthorized
    end

    def current_ability
      @current_ability ||= Spree::Ability.new(current_user)
    end

    def profile
      @profile ||= request.headers["Accept"][/\bprofile="?([^";,\s]+)"?/, 1]
    end

    def import
      DfcIo.import(request.body)
    end

    # Checks weather a feature is enabled for any of the given actors.
    def feature?(feature, *actors)
      OpenFoodNetwork::FeatureToggle.enabled?(feature, *actors)
    end

    def render_dfc(subject = nil, *)
      return render_v1(*subject, *) if profile != "dfc-v2"
      return render_v2(subject, *) unless subject.is_a?(Array)

      # DFCv2 requires containers for listing resources in an index action.
      members = DfcV2Migration.up(*subject)
      container = Container.new(url_for, members:)
      render_v2(container, *subject, *)
    end

    def render_v1(*)
      render json: DfcIo.export(*)
    end

    def render_v2(*)
      objects = DfcV2Migration.up(*)

      render json: DfcLoader.connector_v2.export(*objects),
             content_type: 'application/ld+json; profile="dfc-v2"'
    end
  end
end
