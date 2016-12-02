module Spree
  module Admin
    GeneralSettingsController.class_eval do
    end


    module GeneralSettingsEditPreferences
      def edit
        super
        @preferences_general << :bugherd_api_key
        @preferences_terms_of_service = [:enterprises_require_tos]
      end
    end
    GeneralSettingsController.send(:prepend, GeneralSettingsEditPreferences)
  end
end
