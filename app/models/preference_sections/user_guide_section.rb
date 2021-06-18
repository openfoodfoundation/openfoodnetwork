# frozen_string_literal: true

module PreferenceSections
  class UserGuideSection
    def name
      I18n.t('admin.contents.edit.user_guide')
    end

    def preferences
      [:user_guide_link]
    end
  end
end
