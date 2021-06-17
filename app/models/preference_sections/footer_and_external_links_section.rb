# frozen_string_literal: true

module PreferenceSections
  class FooterAndExternalLinksSection
    def name
      I18n.t('admin.contents.edit.footer_and_external_links')
    end

    def preferences
      [
        :footer_logo,
        :footer_facebook_url,
        :footer_twitter_url,
        :footer_instagram_url,
        :footer_linkedin_url,
        :footer_googleplus_url,
        :footer_pinterest_url,
        :footer_email,
        :community_forum_url,
        :footer_links_md,
        :footer_about_url
      ]
    end
  end
end
