require 'delegate'

module ProductImport
  class ResetAbsent < SimpleDelegator
    attr_reader :products_reset_count

    def initialize(decorated, settings, strategy_factory)
      super(decorated)
      @products_reset_count = 0

      @settings = settings
      @strategy_factory = strategy_factory

      @suppliers_to_reset_products = []
      @suppliers_to_reset_inventories = []
    end

    # For selected enterprises; set stock to zero for all products/inventory
    # that were not listed in the newly uploaded spreadsheet
    def call
      settings.enterprises_to_reset.each do |enterprise_id|
        next unless permission_by_id?(enterprise_id)

        if importing_into_inventory?
          @suppliers_to_reset_inventories << enterprise_id.to_i
        else
          @suppliers_to_reset_products << enterprise_id.to_i
        end
      end

      reset_stock if suppliers_to_reset?
    end

    private

    attr_reader :settings, :strategy_factory

    def reset_stock
      @products_reset_count += strategy.reset
    end

    def strategy
      strategy_factory.new(settings.updated_ids, supplier_ids)
    end

    def supplier_ids
      if @suppliers_to_reset_inventories.present?
        @suppliers_to_reset_inventories
      elsif @suppliers_to_reset_products.present?
        @suppliers_to_reset_products
      end
    end

    def suppliers_to_reset?
      @suppliers_to_reset_inventories.present? ||
        @suppliers_to_reset_products.present?
    end
  end
end
