module ProductImport
  class ResetAbsent
    def initialize(entry_processor, settings, reset_stock_strategy)
      @entry_processor = entry_processor
      @settings = settings
      @reset_stock_strategy = reset_stock_strategy
    end

    # For selected enterprises; set stock to zero for all products/inventory
    # that were not listed in the newly uploaded spreadsheet
    #
    # @return [Integer] number of items affected by the reset
    def call
      settings.enterprises_to_reset.each do |enterprise_id|
        next unless entry_processor.permission_by_id?(enterprise_id)

        reset_stock_strategy << enterprise_id.to_i
      end

      reset_stock
    end

    private

    attr_reader :settings, :reset_stock_strategy, :entry_processor

    def reset_stock
      if reset_stock_strategy.supplier_ids.present?
        reset_stock_strategy.reset
      else
        0
      end
    end
  end
end
