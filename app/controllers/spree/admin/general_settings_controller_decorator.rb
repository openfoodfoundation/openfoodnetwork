module Spree
  module Admin
    GeneralSettingsController.class_eval do
    end

    module GeneralSettingsEditPreferences
      def edit
        super
        @preferences_general << :bugherd_api_key
      end
    end
    GeneralSettingsController.prepend(GeneralSettingsEditPreferences)
  end
end
