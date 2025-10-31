# frozen_string_literal: true

module Api
  module Admin
    class EnterpriseSerializer < ActiveModel::Serializer
      attributes :name, :id, :is_primary_producer, :is_distributor, :sells, :category, :permalink,
                 :payment_method_ids, :shipping_method_ids, :producer_profile_only,
                 :long_description, :preferred_product_selection_from_inventory_only,
                 :preferred_shopfront_message, :preferred_shopfront_closed_message,
                 :preferred_shopfront_taxon_order, :preferred_shopfront_producer_order,
                 :preferred_shopfront_order_cycle_order, :show_customer_names_to_suppliers,
                 :show_customer_contacts_to_suppliers,
                 :preferred_shopfront_product_sorting_method, :owner, :contact, :users,
                 :require_login, :allow_guest_orders, :allow_order_changes,
                 :logo, :promo_image, :terms_and_conditions,
                 :terms_and_conditions_file_name, :terms_and_conditions_updated_at,
                 :preferred_invoice_order_by_supplier, :preferred_product_low_stock_display,
                 :visible, :hide_ofn_navigation, :white_label_logo,
                 :white_label_logo_link, :external_billing_id

      has_one :owner, serializer: Api::Admin::UserSerializer
      has_many :users, serializer: Api::Admin::UserSerializer
      has_one :address, serializer: Api::AddressSerializer
      has_one :business_address, serializer: Api::AddressSerializer

      def logo
        attachment_urls(object.logo, Enterprise::LOGO_SIZES)
      end

      def promo_image
        attachment_urls(object.promo_image, Enterprise::PROMO_IMAGE_SIZES)
      end

      def white_label_logo
        attachment_urls(object.white_label_logo, Enterprise::WHITE_LABEL_LOGO_SIZES)
      end

      def terms_and_conditions
        return unless object.terms_and_conditions.attached?

        Rails.application.routes.url_helpers.
          url_for(object.terms_and_conditions)
      end

      def terms_and_conditions_file_name
        object.terms_and_conditions_blob&.filename
      end

      def terms_and_conditions_updated_at
        object.terms_and_conditions_blob&.created_at&.to_s
      end

      private

      # Returns a hash of URLs for specified versions of an attachment.
      #
      # Example result:
      #
      #   {
      #     thumb: LOGO_THUMB_URL,
      #     small: LOGO_SMALL_URL,
      #     medium: LOGO_MEDIUM_URL
      #   }
      def attachment_urls(attachment, styles)
        return unless attachment.persisted? && attachment.variable?

        styles.index_with do |style|
          Rails.application.routes.url_helpers.
            url_for(attachment.variant(style))
        end
      end
    end
  end
end
