# frozen_string_literal: true

module PreferenceSections
  class HubSignupPageSection
    def name
      I18n.t('admin.contents.edit.hub_signup_page')
    end

    def preferences
      [
        :hub_signup_pricing_table_html,
        :hub_signup_case_studies_html,
        :hub_signup_detail_html
      ]
    end
  end
end
