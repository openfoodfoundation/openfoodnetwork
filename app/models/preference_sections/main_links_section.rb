# frozen_string_literal: true

module PreferenceSections
  class MainLinksSection
    def name
      I18n.t('admin.contents.edit.main_links')
    end

    def preferences
      [
        :menu1,
        :menu1_icon_name,
        :menu2,
        :menu2_icon_name,
        :menu3,
        :menu3_icon_name,
        :menu4,
        :menu4_icon_name,
        :menu5,
        :menu5_icon_name,
        :menu6,
        :menu6_icon_name,
        :menu7,
        :menu7_icon_name
      ]
    end
  end
end
