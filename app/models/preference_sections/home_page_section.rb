# frozen_string_literal: true

module PreferenceSections
  class HomePageSection
    def name
      I18n.t('admin.contents.edit.home_page')
    end

    def preferences
      [
        :home_page_alert_html,
        :home_hero,
        :home_show_stats
      ]
    end
  end
end
