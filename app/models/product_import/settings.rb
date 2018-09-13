module ProductImport
  class Settings
    def initialize(import_settings)
      @import_settings = import_settings
    end

    def defaults(entry)
      @import_settings.key?(:settings) &&
        @import_settings[:settings][entry.supplier_id.to_s] &&
        @import_settings[:settings][entry.supplier_id.to_s]['defaults']
    end
  end
end
