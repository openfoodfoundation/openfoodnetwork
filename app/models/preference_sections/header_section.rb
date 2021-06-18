# frozen_string_literal: true

module PreferenceSections
  class HeaderSection
    def name
      I18n.t('admin.contents.edit.header')
    end

    def preferences
      [
        :logo,
        :logo_mobile,
        :logo_mobile_svg
      ]
    end
  end
end
