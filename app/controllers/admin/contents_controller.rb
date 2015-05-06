module Admin
  class ContentsController < Spree::Admin::BaseController
    def edit
      @preferences_home = [:home_tagline_cta, :home_whats_happening]
      @preferences_footer = [:footer_facebook_url, :footer_twitter_url, :footer_instagram_url, :footer_linkedin_url, :footer_googleplus_url, :footer_pinterest_url, :footer_email, :footer_links_md, :footer_about_url]
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
