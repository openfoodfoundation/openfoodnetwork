# frozen_string_literal: true

module ProductImport
  class Settings
    def initialize(import_settings)
      @import_settings = import_settings
    end

    def defaults(entry)
      @import_settings.key?(:settings) &&
        settings[entry.enterprise_id.to_s] &&
        settings[entry.enterprise_id.to_s]['defaults']
    end

    def settings
      @import_settings[:settings]
    end

    def updated_ids
      @import_settings[:updated_ids]
    end

    def enterprises_to_reset
      @import_settings[:enterprises_to_reset]
    end

    def importing_into_inventory?
      settings && settings['import_into'] == 'inventories'
    end

    def reset_all_absent?
      settings['reset_all_absent']
    end

    def data_for_stock_reset?
      !!(settings && updated_ids && enterprises_to_reset)
    end
  end
end
