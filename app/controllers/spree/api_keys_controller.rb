# frozen_string_literal: true

module Spree
  class ApiKeysController < ::BaseController
    include Spree::Core::ControllerHelpers
    include I18nHelper

    prepend_before_action :load_object

    def create
      @user.generate_api_key

      if @user.save
        flash[:success] = t('spree.api.key_generated')
      end

      redirect_to redirect_path
    end

    def destroy
      @user.spree_api_key = nil

      if @user.save
        flash[:success] = t('spree.api.key_cleared')
      end

      redirect_to redirect_path
    end

    private

    def load_object
      @user ||= find_user
      if @user
        authorize! :update, @user
      else
        redirect_to main_app.login_path
      end
    end

    def find_user
      Spree::User.find_by(id: params[:id]) || spree_current_user
    end

    def redirect_path
      if request.referer.blank? || request.referer.include?(spree.account_path)
        developer_settings_path
      else
        request.referer
      end
    end

    def developer_settings_path
      "#{spree.account_path}#/developer_settings"
    end
  end
end
