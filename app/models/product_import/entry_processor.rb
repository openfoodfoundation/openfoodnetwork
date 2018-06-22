module ProductImport
  class EntryProcessor
    attr_reader :inventory_created, :inventory_updated, :products_created, :variants_created, :variants_updated, :products_reset_count, :supplier_products, :total_supplier_products

    def initialize(importer, validator, import_settings, spreadsheet_data, editable_enterprises, import_time, updated_ids)
      @importer = importer
      @validator = validator
      @import_settings = import_settings
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
      @supplier_products = {}
      @total_supplier_products = 0
    end

    def save_all(entries)
      entries.each do |entry|
        if import_into_inventory?(entry)
          save_to_inventory(entry)
        else
          save_to_product_list(entry)
        end
      end

      @importer.errors.add(:importer, I18n.t(:product_importer_products_save_error)) if total_saved_count.zero?
    end

    def count_existing_items
      @spreadsheet_data.suppliers_index.each do |_supplier_name, supplier_id|
        next unless supplier_id && permission_by_id?(supplier_id)

        products_count =
          if import_into_inventory_by_supplier?(supplier_id)
            VariantOverride.where('variant_overrides.hub_id IN (?)', supplier_id).count
          else
            Spree::Variant.
              not_deleted.
              not_master.
              joins(:product).
              where('spree_products.supplier_id IN (?)', supplier_id).
              count
          end

        @supplier_products[supplier_id] = products_count
        @total_supplier_products += products_count
      end
    end

    def reset_absent_items
      # For selected enterprises; set stock to zero for all products/inventory
      # that were not listed in the newly uploaded spreadsheet
      return if total_saved_count.zero? || @updated_ids.empty? || !@import_settings.key?(:settings)
      suppliers_to_reset_products = []
      suppliers_to_reset_inventories = []

      @import_settings[:settings].each do |enterprise_id, settings|
        suppliers_to_reset_products.push enterprise_id if settings['reset_all_absent'] && permission_by_id?(enterprise_id) && !import_into_inventory_by_supplier?(enterprise_id)
        suppliers_to_reset_inventories.push enterprise_id if settings['reset_all_absent'] && permission_by_id?(enterprise_id) && import_into_inventory_by_supplier?(enterprise_id)
      end

      unless suppliers_to_reset_inventories.empty?
        @products_reset_count += VariantOverride.
          where('variant_overrides.hub_id IN (?)
          AND variant_overrides.id NOT IN (?)', suppliers_to_reset_inventories, @updated_ids).
          update_all(count_on_hand: 0)
      end

      return if suppliers_to_reset_products.empty?

      @products_reset_count += Spree::Variant.joins(:product).
        where('spree_products.supplier_id IN (?)
        AND spree_variants.id NOT IN (?)
        AND spree_variants.is_master = false
        AND spree_variants.deleted_at IS NULL', suppliers_to_reset_products, @updated_ids).
        update_all(count_on_hand: 0)
    end

    def total_saved_count
      @products_created + @variants_created + @variants_updated + @inventory_created + @inventory_updated
    end

    private

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

      save_variant entry
      @variants_updated += 1
    end

    def import_into_inventory?(entry)
      entry.supplier_id && @import_settings[:settings][entry.supplier_id.to_s]['import_into'] == 'inventories'
    end

    def save_new_inventory_item(entry)
      new_item = entry.product_object
      assign_defaults(new_item, entry)
      new_item.import_date = @import_time

      if new_item.valid? && new_item.save
        display_in_inventory(new_item, true)
        @inventory_created += 1
        @updated_ids.push new_item.id
      else
        @importer.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", new_item.errors.full_messages)
      end
    end

    def save_existing_inventory_item(entry)
      existing_item = entry.product_object
      assign_defaults(existing_item, entry)
      existing_item.import_date = @import_time

      if existing_item.valid? && existing_item.save
        display_in_inventory(existing_item)
        @inventory_updated += 1
        @updated_ids.push existing_item.id
      else
        @importer.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", existing_item.errors.full_messages)
      end
    end

    def save_new_product(entry)
      @already_created ||= {}
      # If we've already added a new product with these attributes
      # from this spreadsheet, mark this entry as a new variant with
      # the new product id, as this is a now variant of that product...
      if @already_created[entry.supplier_id] && @already_created[entry.supplier_id][entry.name]
        product_id = @already_created[entry.supplier_id][entry.name]
        @validator.mark_as_new_variant(entry, product_id)
        return
      end

      product = Spree::Product.new
      product.assign_attributes(entry.attributes.except('id'))
      assign_defaults(product, entry)

      if product.save
        ensure_variant_updated(product, entry)
        @products_created += 1
        @updated_ids.push product.variants.first.id
      else
        @importer.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", product.errors.full_messages)
      end

      @already_created[entry.supplier_id] = { entry.name => product.id }
    end

    def save_variant(entry)
      variant = entry.product_object
      assign_defaults(variant, entry)
      variant.import_date = @import_time

      if variant.valid? && variant.save
        @updated_ids.push variant.id
        true
      else
        @importer.errors.add("#{I18n.t('admin.product_import.model.line')} #{line_number}:", variant.errors.full_messages)
        false
      end
    end

    def assign_defaults(object, entry)
      # Assigns a default value for a specified field e.g. category='Vegetables', setting this value
      # either for all entries (overwrite_all), or only for those entries where the field was blank
      # in the spreadsheet (overwrite_empty), depending on selected import settings
      return unless @import_settings.key?(:settings) && @import_settings[:settings][entry.supplier_id.to_s] && @import_settings[:settings][entry.supplier_id.to_s]['defaults']

      @import_settings[:settings][entry.supplier_id.to_s]['defaults'].each do |attribute, setting|
        next unless setting['active']

        case setting['mode']
        when 'overwrite_all'
          object.assign_attributes(attribute => setting['value'])
        when 'overwrite_empty'
          if object.send(attribute).blank? || ((attribute == 'on_hand' || attribute == 'count_on_hand') && entry.on_hand_nil)
            object.assign_attributes(attribute => setting['value'])
          end
        end
      end
    end

    def display_in_inventory(variant_override, is_new = false)
      unless is_new
        existing_item = InventoryItem.where(variant_id: variant_override.variant_id, enterprise_id: variant_override.hub_id).first

        if existing_item
          existing_item.assign_attributes(visible: true)
          existing_item.save
          return
        end
      end

      InventoryItem.new(variant_id: variant_override.variant_id, enterprise_id: variant_override.hub_id, visible: true).save
    end

    def ensure_variant_updated(product, entry)
      # Ensure attributes are correctly copied to a new product's variant
      variant = product.variants.first
      variant.display_name = entry.display_name if entry.display_name
      variant.on_demand = entry.on_demand if entry.on_demand
      variant.import_date = @import_time
      variant.save
    end

    def permission_by_id?(supplier_id)
      @editable_enterprises.value?(Integer(supplier_id))
    end

    def import_into_inventory_by_supplier?(supplier_id)
      @import_settings[:settings] && @import_settings[:settings][supplier_id.to_s] && @import_settings[:settings][supplier_id.to_s]['import_into'] == 'inventories'
    end
  end
end
