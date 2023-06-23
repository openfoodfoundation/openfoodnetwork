# frozen_string_literal: true

module Sets
  class ProductSet < ModelSet
    def initialize(attributes = {})
      super(Spree::Product, [], attributes)
    end

    def save
      @collection_hash.each_value.all? do |product_attributes|
        update_product_attributes(product_attributes)
      end
    end

    def collection_attributes=(attributes)
      @collection = Spree::Product
        .where(id: attributes.each_value.map { |product| product[:id] })
      @collection_hash = attributes
    end

    private

    # A separate method of updating products was required due to an issue with
    # the way Rails' assign_attributes and update behave when
    # delegated attributes of a nested object are updated via the parent object
    # (ie. price of variants). Updating such attributes by themselves did not
    # work using:
    #
    #   product.update(variants_attributes: [{ id: y, price: xx.x }])
    #
    # and so an explicit call to update on each individual variant was
    # required. ie:
    #
    #   variant.update( { price: xx.x } )
    #
    def update_product_attributes(attributes)
      split_taxon_ids!(attributes)

      product = find_model(@collection, attributes[:id])
      return if product.nil?

      update_product(product, attributes)
    end

    def split_taxon_ids!(attributes)
      attributes[:taxon_ids] = attributes[:taxon_ids].split(',') if attributes[:taxon_ids].present?
    end

    def update_product(product, attributes)
      return false unless update_product_only_attributes(product, attributes)

      ExchangeVariantDeleter.new.delete(product) if product.saved_change_to_supplier_id?

      update_product_variants(product, attributes) &&
        update_product_master(product, attributes)
    end

    def update_product_only_attributes(product, attributes)
      variant_related_attrs = [:id, :variants_attributes, :master_attributes]
      product_related_attrs = attributes.except(*variant_related_attrs)
      return true if product_related_attrs.blank?

      product.assign_attributes(product_related_attrs)

      validate_presence_of_unit_value_in_product(product)

      product.errors.empty? && product.save
    end

    def validate_presence_of_unit_value_in_product(product)
      product.variants.each do |variant|
        validate_presence_of_unit_value_in_variant(product, variant)
      end
    end

    def validate_presence_of_unit_value_in_variant(product, variant)
      return unless %w(weight volume).include?(product.variant_unit)
      return if variant.unit_value.present?

      product.errors.add(:unit_value, "can't be blank")
    end

    def update_product_variants(product, attributes)
      return true unless attributes[:variants_attributes]

      update_variants_attributes(product, attributes[:variants_attributes])
    end

    def update_product_master(product, attributes)
      return true unless attributes[:master_attributes]

      create_or_update_variant(product, attributes[:master_attributes])
    end

    def update_variants_attributes(product, variants_attributes)
      variants_attributes.each do |attributes|
        create_or_update_variant(product, attributes)
      end
      product.errors.empty?
    end

    def create_or_update_variant(product, variant_attributes)
      variant = find_model(product.variants, variant_attributes[:id])
      if variant.present?
        variant.update(variant_attributes.except(:id))
      else
        create_variant(product, variant_attributes)
      end
    end

    def create_variant(product, variant_attributes)
      return if variant_attributes.blank?

      on_hand = variant_attributes.delete(:on_hand)
      on_demand = variant_attributes.delete(:on_demand)

      variant = product.variants.create(variant_attributes)

      if variant.errors.present?
        product.errors.merge!(variant.errors)
        return false
      end

      begin
        variant.on_demand = on_demand if on_demand.present?
        variant.on_hand = on_hand.to_i if on_hand.present?
      rescue StandardError => e
        notify_bugsnag(e, product, variant, variant_attributes)
        raise e
      end
    end

    def notify_bugsnag(error, product, variant, variant_attributes)
      Bugsnag.notify(error) do |report|
        report.add_metadata(:product, product.attributes)
        report.add_metadata(:product_error, product.errors.first) unless product.valid?
        report.add_metadata(:variant_attributes, variant_attributes)
        report.add_metadata(:variant, variant.attributes)
        report.add_metadata(:variant_error, variant.errors.first) unless variant.valid?
      end
    end

    def find_model(collection, model_id)
      collection.find do |model|
        model.id.to_s == model_id.to_s && model.persisted?
      end
    end
  end
end
