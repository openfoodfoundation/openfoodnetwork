# frozen_string_literal: true

module Spree
  module Admin
    class BaseController < ApplicationController
      helper 'shared'
      helper 'spree/admin/navigation'
      helper 'spree/admin/orders'
      helper 'admin/injection'
      helper 'admin/orders'
      helper 'admin/enterprises'
      helper 'admin/terms_of_service'
      helper 'enterprise_fees'
      helper 'angular_form'

      layout 'spree/layouts/admin'

      include I18nHelper

      before_action :authorize_admin
      before_action :set_locale
      before_action :warn_invalid_order_cycles, if: :page_load_request?

      # Warn the user when they have an active order cycle with hubs that are not ready
      # for checkout (ie. does not have valid shipping and payment methods).
      def warn_invalid_order_cycles
        return if flash[:notice].present? || session[:displayed_order_cycle_warning]

        warning = OrderCycles::WarningService.new(spree_current_user).call
        return if warning.blank?

        flash.now[:notice] = warning
        session[:displayed_order_cycle_warning] = true
      end

      protected

      def model_class
        const_name = controller_name.classify
        return "Spree::#{const_name}".constantize if Object.const_defined?("Spree::#{const_name}")

        nil
      end

      def action
        params[:action].to_sym
      end

      def authorize_admin
        if respond_to?(:model_class, true) && model_class
          record = model_class
        else
          # This allows specificity for each non-resource controller
          #   (to be consistent with "authorize_resource :class => false", see https://github.com/ryanb/cancan/blob/60cf6a67ef59c0c9b63bc27ea0101125c4193ea6/lib/cancan/controller_resource.rb#L146)
          record = self.class.to_s.
            sub("Controller", "").
            underscore.split('/').last.singularize.to_sym
        end
        authorize! :admin, record
        authorize! resource_authorize_action, record
      end

      def resource_authorize_action
        action
      end

      def flash_message_for(object, event_sym)
        resource_desc  = object.class.model_name.human
        resource_desc += " \"#{object.name}\"" if object.respond_to?(:name) && object.name.present?
        I18n.t(event_sym, resource: resource_desc)
      end

      # Index request for JSON needs to pass a CSRF token in order to prevent JSON Hijacking
      def check_json_authenticity
        return unless request.format.js? || request.format.json?

        return unless protect_against_forgery?

        auth_token = params[request_forgery_protection_token]
        return if auth_token && form_authenticity_token == CGI.unescape(auth_token)

        raise(ActionController::InvalidAuthenticityToken)
      end

      private

      def page_load_request?
        return false if request.format.include?('turbo')

        html_request?
      end

      def html_request?
        request.format.html?
      end

      def json_request?
        request.format.json?
      end

      def render_as_json(data, options = {})
        ams_prefix = options.delete :ams_prefix
        if each_serializer_required?(data)
          render options.merge(json: data, each_serializer: serializer(ams_prefix))
        else
          render options.merge(json: data, serializer: serializer(ams_prefix))
        end
      end

      def each_serializer_required?(data)
        ['Array', 'ActiveRecord::Relation'].include?(data.class.name)
      end

      def serializer(ams_prefix)
        unless ams_prefix.nil? || ams_prefix_whitelist.include?(ams_prefix.to_sym)
          raise "Suffix '#{ams_prefix}' not found in ams_prefix_whitelist for #{self.class.name}."
        end

        prefix = ams_prefix&.classify || ""
        name = controller_name.classify
        "::Api::Admin::#{prefix}#{name}Serializer".constantize
      end
    end
  end
end
