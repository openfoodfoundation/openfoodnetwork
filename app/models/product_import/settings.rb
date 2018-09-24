module ProductImport
  class Settings
    def initialize(import_settings)
      @import_settings = import_settings
    end

    def defaults(entry)
      @import_settings.key?(:settings) &&
        settings[entry.supplier_id.to_s] &&
        settings[entry.supplier_id.to_s]['defaults']
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
  end
end
