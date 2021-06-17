# frozen_string_literal: true

module PreferenceSections
  class ProducerSignupPageSection
    def name
      I18n.t('admin.contents.edit.producer_signup_page')
    end

    def preferences
      [
        :producer_signup_pricing_table_html,
        :producer_signup_case_studies_html,
        :producer_signup_detail_html
      ]
    end
  end
end
