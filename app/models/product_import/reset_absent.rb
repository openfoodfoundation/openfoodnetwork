# frozen_string_literal: true

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
      reset_stock_strategy.reset(authorized_enterprises)
    end

    private

    attr_reader :settings, :reset_stock_strategy, :entry_processor

    # Returns the enterprises that have permissions to be reset
    #
    # @return [Array<Integer>] array of Enterprise ids
    def authorized_enterprises
      settings.enterprises_to_reset.map do |enterprise_id|
        next unless entry_processor.permission_by_id?(enterprise_id)

        enterprise_id.to_i
      end
    end
  end
end
