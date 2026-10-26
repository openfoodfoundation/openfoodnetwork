# frozen_string_literal: true

module Admin
  # Super admins register the external applications allowed to log in OFN
  # users through OAuth2 (see config/initializers/doorkeeper.rb).
  class OauthApplicationsController < Spree::Admin::BaseController
    before_action :load_application, only: [:edit, :update, :destroy]

    def index
      @applications = Doorkeeper::Application.order(:name)
    end

    def new
      @application = Doorkeeper::Application.new
    end

    def edit; end

    def create
      @application = Doorkeeper::Application.new(permitted_params)

      if @application.save
        flash[:success] = t(:successfully_created, resource: @application.name)
        redirect_to main_app.edit_admin_oauth_application_path(@application)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @application.update(permitted_params)
        flash[:success] = t(:successfully_updated, resource: @application.name)
        redirect_to main_app.admin_oauth_applications_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @application.destroy!
      flash[:success] = t(:successfully_removed, resource: @application.name)
      redirect_to main_app.admin_oauth_applications_path
    end

    private

    def load_application
      @application = Doorkeeper::Application.find(params[:id])
    end

    def permitted_params
      params.require(:oauth_application).permit(:name, :redirect_uri, :confidential)
    end
  end
end
