module Admin
  class ContentsController < Spree::Admin::BaseController
    def edit
      @preference_sections = [{name: I18n.t('admin.contents.edit.header'), preferences: [:logo, :logo_mobile, :logo_mobile_svg]},
                              {name: I18n.t('admin.contents.edit.home_page'), preferences: [:home_hero, :home_show_stats]},
                              {name: I18n.t('admin.contents.edit.producer_signup_page'), preferences: [:producer_signup_pricing_table_html, :producer_signup_case_studies_html, :producer_signup_detail_html]},
                              {name: I18n.t('admin.contents.edit.hub_signup_page'), preferences: [:hub_signup_pricing_table_html, :hub_signup_case_studies_html, :hub_signup_detail_html]},
                              {name: I18n.t('admin.contents.edit.group_signup_page'), preferences: [:group_signup_pricing_table_html, :group_signup_case_studies_html, :group_signup_detail_html]},
                              {name: I18n.t('admin.contents.edit.footer_and_external_links'), preferences: [:footer_logo,
                                                             :footer_facebook_url, :footer_twitter_url, :footer_instagram_url, :footer_linkedin_url, :footer_googleplus_url, :footer_pinterest_url,
                                                             :footer_email, :community_forum_url, :footer_links_md, :footer_about_url, :footer_tos_url]}]
    end

    def update
      params.each do |name, value|
        if ContentConfig.has_preference?(name) || ContentConfig.has_attachment?(name)
          ContentConfig.send("#{name}=", value)
        end
      end

      # Save any uploaded images
      ContentConfig.save

      flash[:success] = t(:successfully_updated, :resource => I18n.t('admin.contents.edit.your_content'))

      redirect_to main_app.edit_admin_content_path
    end
  end
end
