# frozen_string_literal: true

# This class handles the saving of new product, variant, and inventory records created during
# product import. It also collates data regarding this process for user feedback, as the import
# is processed in small stages sequentially over a number of requests.

module ProductImport
  class EntryProcessor
    attr_reader :inventory_created, :inventory_updated, :products_created,
                :variants_created, :variants_updated, :enterprise_products,
                :total_enterprise_products, :products_reset_count

    def initialize(importer, validator, import_settings, spreadsheet_data,
                   editable_enterprises, import_time, updated_ids)
      @importer = importer
      @validator = validator
      @settings = Settings.new(import_settings)
      @spreadsheet_data = spreadsheet_data
      @editable_enterprises = editable_enterprises
      @import_time = import_time
      @updated_ids = updated_ids

      @inventory_created = 0
      @inventory_updated = 0
      @products_created = 0
      @variants_created = 0
      @variants_updated = 0
      @products_reset_count = 0
      @enterprise_products = {}
      @total_enterprise_products = 0
    end

    def save_all(entries)
      entries.each do |entry|
        if settings.importing_into_inventory?
          save_to_inventory(entry)
        else
          save_to_product_list(entry)
        end
      end

      if total_saved_count.zero?
        @importer.errors.add(:importer,
                             I18n.t(:product_importer_products_save_error))
      end
    end

    def count_existing_items
      @spreadsheet_data.enterprises_index.each do |_enterprise_name, attrs|
        enterprise_id = attrs[:id]
        next unless enterprise_id && permission_by_id?(enterprise_id)

        products_count =
          if settings.importing_into_inventory?
            VariantOverride.for_hubs([enterprise_id]).count
          else
            Spree::Variant.
              joins(:product).
              where('spree_products.supplier_id IN (?)', enterprise_id).
              count
          end

        @enterprise_products[enterprise_id] = products_count
        @total_enterprise_products += products_count
      end
    end

    def reset_absent_items
      return unless settings.data_for_stock_reset? && settings.reset_all_absent?

      @products_reset_count = reset_absent.call
    end

    def reset_absent
      @reset_absent ||= ResetAbsent.new(self, settings, reset_stock_strategy)
    end

    def reset_stock_strategy_factory
      if settings.importing_into_inventory?
        InventoryResetStrategy
      else
        Catalog::ProductImport::ProductsResetStrategy
      end
    end

    def reset_stock_strategy
      @reset_stock_strategy ||= reset_stock_strategy_factory
        .new(settings.updated_ids)
    end

    def total_saved_count
      [@products_created, @variants_created, @variants_updated,
       @inventory_created, @inventory_updated].sum
    end

    def permission_by_id?(enterprise_id)
      @editable_enterprises.value?(Integer(enterprise_id))
    end

    private

    attr_reader :settings

    def save_to_inventory(entry)
      save_new_inventory_item entry if entry.validates_as? 'new_inventory_item'
      save_existing_inventory_item entry if entry.validates_as? 'existing_inventory_item'
    end

    def save_to_product_list(entry)
      save_new_product entry if entry.validates_as? 'new_product'

      if entry.validates_as? 'new_variant'
        save_variant entry
        @variants_created += 1
      end

      return unless entry.validates_as? 'existing_variant'

      begin
        save_variant entry
      rescue ActiveRecord::StaleObjectError
        entry.product_object.reload
        save_variant entry
      end

      @variants_updated += 1
    end

    def save_new_inventory_item(entry)
      new_item = entry.product_object
      new_item.import_date = @import_time

      if new_item.valid? && new_item.save
        display_in_inventory(new_item, true)
        @inventory_created += 1
        @updated_ids.push new_item.id
      else
        assign_errors new_item.errors.full_messages, entry.line_number
      end
    end

    def save_existing_inventory_item(entry)
      existing_item = entry.product_object
      existing_item.import_date = @import_time

      if existing_item.valid? && existing_item.save
        display_in_inventory(existing_item)
        @inventory_updated += 1
        @updated_ids.push existing_item.id
      else
        assign_errors existing_item.errors.full_messages, entry.line_number
      end
    end

    def save_new_product(entry)
      @already_created ||= {}
      # If we've already added a new product with these attributes
      # from this spreadsheet, mark this entry as a new variant with
      # the new product id, as this is a now variant of that product...
      if @already_created[entry.enterprise_id] &&
         @already_created[entry.enterprise_id][entry.name]

        product_id = @already_created[entry.enterprise_id][entry.name]
        @validator.mark_as_new_variant(entry, product_id)
        return
      end

      product = Spree::Product.new
      product.assign_attributes(
        entry.assignable_attributes.except('id', 'on_hand', 'on_demand', 'display_name')
      )
      product.supplier_id = entry.producer_id

      if product.save
        ensure_variant_updated(product, entry)
        @products_created += 1
        @updated_ids.push product.variants.first.id
      else
        assign_errors product.errors.full_messages, entry.line_number
      end

      @already_created.deep_merge! entry.enterprise_id => { entry.name => product.id }
    end

    def save_variant(entry)
      variant = entry.product_object
      variant.import_date = @import_time

      if variant.valid? && variant.save
        @updated_ids.push variant.id
        true
      else
        assign_errors variant.errors.full_messages, entry.line_number
        false
      end
    end

    def assign_errors(errors, line_number)
      @importer.errors.add(
        I18n.t('admin.product_import.model.line_number',
               number: line_number),
        errors
      )
    end

    def display_in_inventory(variant_override, is_new = false)
      unless is_new
        existing_item = InventoryItem.where(
          variant_id: variant_override.variant_id,
          enterprise_id: variant_override.hub_id
        ).first

        if existing_item
          existing_item.assign_attributes(visible: true)
          existing_item.save
          return
        end
      end

      InventoryItem.new(
        variant_id: variant_override.variant_id,
        enterprise_id: variant_override.hub_id,
        visible: true
      ).save
    end

    def ensure_variant_updated(product, entry)
      # Ensure attributes are correctly copied to a new product's variant
      variant = product.variants.first
      variant.display_name = entry.display_name if entry.display_name
      variant.on_demand = entry.on_demand if entry.on_demand
      variant.on_hand = entry.on_hand if entry.on_hand
      variant.import_date = @import_time
      variant.save
    end
  end
end
