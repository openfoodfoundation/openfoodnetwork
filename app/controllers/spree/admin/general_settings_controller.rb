# frozen_string_literal: true

module Spree
  module Admin
    class GeneralSettingsController < Spree::Admin::BaseController
      def edit
        @preferences_general = [:site_name, :default_seo_title, :default_meta_keywords,
                                :default_meta_description, :site_url]
        @preferences_currency = [:display_currency, :hide_cents]
      end

      def update
        merge_available_units_params unless params[:available_units].nil?
        params.each do |name, value|
          next unless Spree::Config.has_preference? name

          Spree::Config[name] = value
        end
        flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:general_settings))

        redirect_to spree.edit_admin_general_settings_path
      end

      private

      def merge_available_units_params
        params[:available_units] =
          params[:available_units].select { |_unit, checked| checked == "1" }.keys.join(",")
      end
    end
  end
end
