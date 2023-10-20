# frozen_string_literal: true

module Sets
  # Accepts a collection_hash in format:
  # {
  #   0=> {id:"7449", name:"Pommes"},
  #   1=> {...}
  # }
  #
  class ProductSet < ModelSet
    def initialize(attributes = {})
      super(Spree::Product, [], attributes)
    end

    def save
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
      split_taxon_ids!(attributes)

      product = find_model(@collection, attributes[:id])
      return if product.nil?

      update_product(product, attributes)
    end

    def split_taxon_ids!(attributes)
      attributes[:taxon_ids] = attributes[:taxon_ids].split(',') if attributes[:taxon_ids].present?
    end

    def update_product(product, attributes)
      return false unless assign_product_attributes(product, attributes) &&
        assign_variant_attributes(product, attributes[:variants_attributes])

      # save products
      # save variatnts
      # and then set variant on_hand/on_demand values
      return false unless product.save && save_variants(product, attributes[:variants_attributes])

      ExchangeVariantDeleter.new.delete(product) if product.saved_change_to_supplier_id?

      # update_product_variants(product, attributes)
    end

    ## 1. Assign and validate
    def assign_product_attributes(product, attributes)
      variant_related_attrs = [:id, :variants_attributes]
      product_related_attrs = attributes.except(*variant_related_attrs)
      return true if product_related_attrs.blank?

      product.assign_attributes(product_related_attrs)

      validate_presence_of_unit_value_in_product(product)

      product.errors.empty? && product.valid?
    end

    def assign_variant_attributes(product, variants_attributes)
      variants_attributes&.each do |attributes|
        new_or_assign_variant(product, attributes)
      end
      product.errors.empty?
    end

    def new_or_assign_variant(product, variant_attributes)
      variant = find_model(product.variants, variant_attributes[:id])

      if variant.present?
        variant.assign_attributes(variant_attributes.except(:id))
      else
        # 'You need to save the variant to create a stock item before you can set stock levels.'
        # we need to keep a refernence to newly created variants, so we know which ones to .save later.
        variant = product.variants.new(variant_attributes.except(:on_hand, :on_demand))
      end

      product.errors.merge!(variant.errors) unless variant.valid?
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


    ## 2. Save records
    def save_variants(product, variants_attributes)
      #todo
        variant = find_model(product.variants, attributes[:id])

      variants = existing_Variants + new_Variants

      variants&.all? do |attributes|
        variant.save
        set_stock_levels(variant, attributes)
      end
    end

    def set_stock_levels(variant, attributes)
      begin
        variant.on_demand = on_demand if attributes[:on_demand].present?
        variant.on_hand = on_hand.to_i if attributes[:on_hand].present?
      rescue StandardError => e
        notify_bugsnag(e, product, variant, attributes)
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
  end
end
