module Admin
  class ContentsController < Spree::Admin::BaseController
    def edit
      @preferences = [:home_tagline_cta, :home_whats_happening, :footer_about_url]
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
