# frozen_string_literal: true

module PreferenceSections
  class MainLinksSection
    def name
      I18n.t('admin.contents.edit.main_links')
    end

    def preferences
      [
        :menu_1,
        :menu_1_icon_name,
        :menu_2,
        :menu_2_icon_name,
        :menu_3,
        :menu_3_icon_name,
        :menu_4,
        :menu_4_icon_name,
        :menu_5,
        :menu_5_icon_name,
        :menu_6,
        :menu_6_icon_name,
        :menu_7,
        :menu_7_icon_name
      ]
    end
  end
end
