module Admin
  class ContentsController < Spree::Admin::BaseController
    def edit
      @preference_sections = preference_sections.map do |preference_section|
        { name: preference_section.name, preferences: preference_section.preferences }
      end
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

    private

    def preference_sections
      Dir["app/models/preference_sections/*.rb"].map do |filename|
        basename = 'PreferenceSections::' + File.basename(filename, '.rb').camelize
        basename.constantize.new
      end
    end
  end
end
