# frozen_string_literal: true

module Spree
  module Admin
    class MailMethodsController < Spree::Admin::BaseController
      after_action :initialize_mail_settings

      def update
        params.each do |name, value|
          next unless Spree::Config.has_preference? name

          Spree::Config[name] = value
        end

        flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:mail_method_settings))
        render :edit
      end

      def testmail
        if TestMailer.test_email(spree_current_user).deliver_now
          flash[:success] = Spree.t('admin.mail_methods.testmail.delivery_success')
        else
          flash[:error] = Spree.t('admin.mail_methods.testmail.delivery_error')
        end
      rescue StandardError => e
        flash[:error] = Spree.t('admin.mail_methods.testmail.error') % { e: e }
      ensure
        redirect_to spree.edit_admin_mail_methods_url
      end

      private

      def initialize_mail_settings
        Spree::Core::MailSettings.init
      end
    end
  end
end
