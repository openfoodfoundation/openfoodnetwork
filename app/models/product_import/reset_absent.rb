require 'delegate'

module ProductImport
  class ResetAbsent < SimpleDelegator
    attr_reader :products_reset_count

    def initialize(decorated, settings, strategy_factory)
      super(decorated)
      @products_reset_count = 0

      @settings = settings
      @strategy_factory = strategy_factory
    end

    # For selected enterprises; set stock to zero for all products/inventory
    # that were not listed in the newly uploaded spreadsheet
    def call
      settings.enterprises_to_reset.each do |enterprise_id|
        next unless permission_by_id?(enterprise_id)

        strategy << enterprise_id.to_i
      end

      reset_stock if strategy.supplier_ids
    end

    private

    attr_reader :settings, :strategy_factory

    def reset_stock
      @products_reset_count += strategy.reset(
        settings.updated_ids,
        strategy.supplier_ids
      )
    end
  end
end
