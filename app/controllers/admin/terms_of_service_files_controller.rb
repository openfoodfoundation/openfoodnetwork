# frozen_string_literal: true

module Admin
  class TermsOfServiceFilesController < Spree::Admin::BaseController
    def show
      @current_file = TermsOfServiceFile.current
      @new_file = TermsOfServiceFile.new
    end

    def new
      show
      render :show
    end

    def create
      TermsOfServiceFile.create!(file_params)
      redirect_to main_app.admin_terms_of_service_files_path
    rescue ActionController::ParameterMissing
      flash[:error] = t(".select_file")
      redirect_to main_app.admin_terms_of_service_files_path
    end

    def destroy
      TermsOfServiceFile.current.destroy!
      redirect_to main_app.admin_terms_of_service_files_path
    end

    private

    # Needed by Spree::Admin::BaseController#authorize_admin or it
    # tries to find a Spree model.
    def model_class
      TermsOfServiceFile
    end

    def file_params
      params.require(:terms_of_service_file).permit(:attachment)
    end
  end
end
