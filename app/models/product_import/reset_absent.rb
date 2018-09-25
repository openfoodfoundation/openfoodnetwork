module ProductImport
  class ResetAbsent
    attr_reader :products_reset_count

    def initialize(entry_processor, settings, strategy)
      @entry_processor = entry_processor
      @settings = settings
      @strategy = strategy

      @products_reset_count = 0
    end

    # For selected enterprises; set stock to zero for all products/inventory
    # that were not listed in the newly uploaded spreadsheet
    def call
      settings.enterprises_to_reset.each do |enterprise_id|
        next unless entry_processor.permission_by_id?(enterprise_id)

        strategy << enterprise_id.to_i
      end

      reset_stock if strategy.supplier_ids.present?
    end

    private

    attr_reader :settings, :strategy, :entry_processor

    def reset_stock
      @products_reset_count += strategy.reset
    end
  end
end
