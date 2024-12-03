# frozen_string_literal: true

module Admin
  class ConnectedAppsController < ApplicationController
    def create
      authorize! :admin, enterprise

      connect

      render_panel
    end

    def destroy
      authorize! :admin, enterprise

      app = enterprise.connected_apps.find(params.require(:id))
      app.destroy

      render_panel
    end

    private

    def create_connected_app
      attributes = {}
      attributes[:type] = connected_app_params[:type] if connected_app_params[:type]

      @app = ConnectedApp.create!(enterprise_id: enterprise.id, **attributes)
    end

    def connect
      return connect_vine if connected_app_params[:type] == "ConnectedApps::Vine"

      create_connected_app
      @app.connect(api_key: spree_current_user.spree_api_key,
                   channel: SessionChannel.for_request(request))
    end

    def connect_vine
      if vine_params_empty?
        return flash[:error] =
                 I18n.t("admin.enterprises.form.connected_apps.vine.api_parameters_empty")
      end

      create_connected_app

      jwt_service = Vine::JwtService.new(secret: connected_app_params[:vine_secret])
      vine_api = Vine::ApiService.new(api_key: connected_app_params[:vine_api_key],
                                      jwt_generator: jwt_service)

      if !@app.connect(api_key: connected_app_params[:vine_api_key],
                       secret: connected_app_params[:vine_secret], vine_api:)
        error_message = "#{@app.errors.full_messages.to_sentence}. \
          #{I18n.t('admin.enterprises.form.connected_apps.vine.api_parameters_error')}".squish
        handle_error(error_message)
      end
    rescue Faraday::Error => e
      log_and_notify_exception(e)
      handle_error(I18n.t("admin.enterprises.form.connected_apps.vine.connection_error"))
    rescue KeyError => e
      log_and_notify_exception(e)
      handle_error(I18n.t("admin.enterprises.form.connected_apps.vine.setup_error"))
    end

    def enterprise
      @enterprise ||= Enterprise.find(params.require(:enterprise_id))
    end

    def render_panel
      redirect_to "#{edit_admin_enterprise_path(enterprise)}#/connected_apps_panel"
    end

    def handle_error(message)
      flash[:error] = message
      @app.destroy
    end

    def log_and_notify_exception(exception)
      Rails.logger.error exception.inspect
      Alert.raise(exception)
    end

    def vine_params_empty?
      connected_app_params[:vine_api_key].empty? || connected_app_params[:vine_secret].empty?
    end

    def connected_app_params
      params.permit(:type, :vine_api_key, :vine_secret)
    end
  end
end
