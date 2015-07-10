module Admin
  class ContentsController < Spree::Admin::BaseController
    def edit
      @preference_sections = [{name: 'Home page', preferences: [:home_tagline_cta, :home_whats_happening]},
                              {name: 'Producer signup page', preferences: [:producer_signup_pricing_table_html, :producer_signup_case_studies_html, :producer_signup_detail_html]},
                              {name: 'Hub signup page', preferences: [:hub_signup_pricing_table_html, :hub_signup_case_studies_html, :hub_signup_detail_html]},
                              {name: 'Footer', preferences: [:footer_facebook_url, :footer_twitter_url, :footer_instagram_url, :footer_linkedin_url, :footer_googleplus_url, :footer_pinterest_url, :footer_email, :footer_links_md, :footer_about_url]}]
    end

    def update
      params.each do |name, value|
        next unless ContentConfig.has_preference? name
        ContentConfig[name] = value
      end
      flash[:success] = t(:successfully_updated, :resource => "Your content")

      redirect_to main_app.edit_admin_content_path
    end
  end
end
