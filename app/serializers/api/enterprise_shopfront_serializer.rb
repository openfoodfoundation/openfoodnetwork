# frozen_string_literal: true

# Represents the properties of an Enterprise when viewing the details of listed shopfronts
module Api
  class EnterpriseShopfrontSerializer < ActiveModel::Serializer
    include SerializerHelper

    attributes :name, :id, :description, :latitude, :longitude, :long_description, :website,
               :instagram, :linkedin, :twitter, :facebook, :is_primary_producer, :is_distributor,
               :phone, :whatsapp_phone, :whatsapp_url, :visible, :email_address, :hash, :logo,
               :promo_image, :path, :category, :active, :producers, :orders_close_at, :hubs,
               :taxons, :supplied_taxons, :pickup, :delivery, :preferred_product_low_stock_display,
               :hide_ofn_navigation, :white_label_logo, :white_label_logo_link

    has_one :address, serializer: Api::AddressSerializer
    has_many :supplied_properties, serializer: Api::PropertySerializer
    has_many :distributed_properties, serializer: Api::PropertySerializer

    def orders_close_at
      OrderCycle.with_distributor(enterprise).soonest_closing.first&.orders_close_at
    end

    def active
      @active ||=
        enterprise.ready_for_checkout? && OrderCycle.active.with_distributor(enterprise).exists?
    end

    def pickup
      shipping_types? :pickup
    end

    def delivery
      shipping_types? :delivery
    end

    def email_address
      enterprise.email_address.to_s.reverse
    end

    def hash
      enterprise.to_param
    end

    def logo
      enterprise.logo_url(:medium)
    end

    def promo_image
      enterprise.promo_image_url(:large)
    end

    def white_label_logo
      enterprise.white_label_logo_url
    end

    def path
      enterprise_shop_path(enterprise)
    end

    def producers
      ActiveModel::ArraySerializer.new(
        enterprise.plus_parents_and_order_cycle_producers(
          OrderCycle.not_closed.with_distributor(enterprise)
        ),
        each_serializer: Api::EnterpriseThinSerializer
      )
    end

    def hubs
      ActiveModel::ArraySerializer.new(
        enterprise.distributors.not_hidden, each_serializer: Api::EnterpriseThinSerializer
      )
    end

    def taxons
      taxons = active ? enterprise.current_distributed_taxons : enterprise.distributed_taxons

      ActiveModel::ArraySerializer.new(
        taxons, each_serializer: Api::TaxonSerializer
      )
    end

    def supplied_taxons
      return [] unless enterprise.is_primary_producer

      ActiveModel::ArraySerializer.new(
        enterprise.supplied_taxons, each_serializer: Api::TaxonSerializer
      )
    end

    def supplied_properties
      return [] unless enterprise.is_primary_producer

      (product_properties + producer_properties).uniq do |property_object|
        property_object.property.presentation
      end
    end

    def distributed_properties
      (distributed_product_properties + distributed_producer_properties).uniq do |property_object|
        property_object.property.presentation
      end
    end

    def distributed_product_properties
      properties = Spree::Property.joins(products: { variants: { exchanges: :order_cycle } })
        .merge(Exchange.outgoing)
        .merge(Exchange.to_enterprise(enterprise))
        .select('DISTINCT spree_properties.*')

      return properties.merge(OrderCycle.active) if active

      properties
    end

    def distributed_producer_properties
      properties = Spree::Property.joins(
        producer_properties: {
          producer: { supplied_products: { variants: { exchanges: :order_cycle } } }
        }
      )
        .merge(Exchange.outgoing).merge(Exchange.to_enterprise(enterprise))
        .select('DISTINCT spree_properties.*')

      return properties.merge(OrderCycle.active) if active

      properties
    end

    private

    def product_properties
      enterprise.supplied_products.includes(:properties).flat_map(&:properties)
    end

    def producer_properties
      enterprise.properties
    end

    def enterprise
      object
    end

    def shipping_types?(type)
      require_shipping = type == :delivery ? 't' : 'f'
      Spree::ShippingMethod.
        joins(:distributor_shipping_methods).
        where('distributors_shipping_methods.distributor_id = ?', enterprise.id).
        where("spree_shipping_methods.require_ship_address = '#{require_shipping}'").exists?
    end
  end
end
