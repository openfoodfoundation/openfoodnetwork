# frozen_string_literal: true

require 'api/admin/enterprise_serializer'

module Api
  module V0
    class EnterpriseAttachmentController < Api::V0::BaseController
      class MissingImplementationError < StandardError; end

      class UnknownEnterpriseAuthorizationActionError < StandardError; end

      before_action :load_enterprise

      respond_to :json

      def destroy
        unless @enterprise.public_send(attachment_name).attached?
          return respond_with_conflict(error: destroy_attachment_does_not_exist_error_message)
        end

        @enterprise.update!(attachment_name => nil)
        render json: @enterprise,
               serializer: Admin::EnterpriseSerializer,
               spree_current_user: spree_current_user
      end

      protected

      def attachment_name
        raise MissingImplementationError, "Method attachment_name should be defined"
      end

      def enterprise_authorize_action
        raise MissingImplementationError, "Method enterprise_authorize_action should be defined"
      end

      def load_enterprise
        @enterprise = Enterprise.find_by(permalink: params[:enterprise_id].to_s)
        raise UnknownEnterpriseAuthorizationActionError if enterprise_authorize_action.blank?

        authorize!(enterprise_authorize_action, @enterprise)
      end

      def destroy_attachment_does_not_exist_error_message
        I18n.t("api.enterprise_#{attachment_name}.destroy_attachment_does_not_exist")
      end
    end
  end
end
