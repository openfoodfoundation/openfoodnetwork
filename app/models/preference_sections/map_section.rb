# frozen_string_literal: true

module PreferenceSections
  class MapSection
    def name
      I18n.t('admin.contents.edit.map')
    end

    def preferences
      [
        :open_street_map_enabled,
        :open_street_map_provider_name,
        :open_street_map_provider_options
      ]
    end
  end
end
