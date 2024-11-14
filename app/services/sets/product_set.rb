# frozen_string_literal: true

module Sets
  # Accepts a collection_hash in format:
  # {
  #   0=> {id:"7449", name:"Pommes"},
  #   1=> {...}
  # }
  #
  class ProductSet < ModelSet
    attr_reader :saved_count

    def initialize(attributes = {})
      super(Spree::Product, [], attributes)
    end

    def save
      @saved_count = 0

      # Attempt to save all records, collecting model errors.
      @collection_hash.each_value.map do |product_attributes|
        update_product_attributes(product_attributes)
      end.all?
    end

    def collection_attributes=(attributes)
      ids = attributes.values.pluck(:id).compact
      # Find and load existing products in the order they are provided
      @collection = Spree::Product.find(ids)
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
      product = find_model(@collection, attributes[:id])
      return if product.nil?

      update_product(product, attributes)
    end

    def update_product(product, attributes)
      return false unless update_product_only_attributes(product, attributes)

      update_product_variants(product, attributes)
    end

    def update_product_only_attributes(product, attributes)
      variant_related_attrs = [:id, :variants_attributes]
      product_related_attrs = attributes.except(*variant_related_attrs)
      return true if product_related_attrs.blank?

      product.assign_attributes(product_related_attrs)

      return true unless product.changed?

      validate_presence_of_unit_value_in_product(product)

      success = product.errors.empty? && product.save
      count_result(success)
      success
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

    def update_variants_attributes(product, variants_attributes)
      variants_attributes.each do |attributes|
        create_or_update_variant(product, attributes)
      end
      product.errors.empty?
    end

    def create_or_update_variant(product, variant_attributes)
      variant = find_model(product.variants, variant_attributes[:id])
      if variant.present?
        variant.assign_attributes(variant_attributes.except(:id))
        variant.save if variant.changed?

        ExchangeVariantDeleter.new.delete(variant) if variant.saved_change_to_supplier_id?
      else
        variant = create_variant(product, variant_attributes)
      end

      # Copy any variant errors to product
      variant&.errors&.each do |error|
        # The name is namespaced to avoid confusion with product attrs of same name.
        product.errors.add(:"variant_#{error.attribute}", error.message)
      end
      variant&.errors.blank?
    end

    def create_variant(product, variant_attributes)
      return if variant_attributes.blank?

      # 'You need to save the variant to create a stock item before you can set stock levels.'
      on_hand = variant_attributes.delete(:on_hand)
      on_demand = variant_attributes.delete(:on_demand)

      variant = product.variants.create(variant_attributes)
      return variant if variant.errors.present?

      begin
        variant.on_demand = on_demand if on_demand.present?
        variant.on_hand = on_hand.to_i if on_hand.present?
      rescue StandardError => e
        notify_bugsnag(e, product, variant, variant_attributes)
        raise e
      end

      variant
    end

    def count_result(saved)
      @saved_count += 1 if saved
    end

    def notify_bugsnag(error, product, variant, variant_attributes)
      Bugsnag.notify(error) do |report|
        report.add_metadata( :product_set,
                             { product: product.attributes, variant_attributes:,
                               variant: variant.attributes } )
        report.add_metadata(:product_set, :product_error, product.errors.first) if !product.valid?
        report.add_metadata(:product_set, :variant_error, variant.errors.first) if !variant.valid?
      end
    end
  end
end
