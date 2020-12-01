# frozen_string_literal: true

module PermittedAttributes
  class Enterprise
    def initialize(params)
      @params = params
    end

    def call
      return @params[:enterprise] if @params[:enterprise].blank?

      @params.require(:enterprise).permit(self.class.attributes)
    end

    def self.attributes
      basic_permitted_attributes + [
        group_ids: [], user_ids: [],
        shipping_method_ids: [], payment_method_ids: [],
        address_attributes: PermittedAttributes::Address.attributes,
        producer_properties_attributes: [:id, :property_name, :value, :_destroy]
      ]
    end

    def self.basic_permitted_attributes
      [
        :id, :name, :visible, :permalink, :owner_id, :contact_name, :email_address, :phone,
        :is_primary_producer, :sells, :website, :facebook, :instagram, :linkedin, :twitter,
        :description, :long_description, :logo, :promo_image, :terms_and_conditions,
        :allow_guest_orders, :allow_order_changes, :require_login, :enable_subscriptions,
        :abn, :acn, :charges_sales_tax, :display_invoice_logo, :invoice_text,
        :preferred_product_selection_from_inventory_only, :preferred_shopfront_message,
        :preferred_shopfront_closed_message, :preferred_shopfront_taxon_order,
        :preferred_shopfront_order_cycle_order, :preferred_show_customer_names_to_suppliers
      ]
    end
  end
end
