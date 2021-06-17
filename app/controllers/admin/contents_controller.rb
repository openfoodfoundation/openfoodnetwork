# frozen_string_literal: true

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
          ContentConfig.public_send("#{name}=", value)
        end
      end

      # Save any uploaded images
      ContentConfig.save

      flash[:success] =
        t(:successfully_updated, resource: I18n.t('admin.contents.edit.your_content'))

      redirect_to main_app.edit_admin_contents_path
    end

    private

    def preference_sections
      [
        PreferenceSections::HeaderSection.new,
        PreferenceSections::HomePageSection.new,
        PreferenceSections::ProducerSignupPageSection.new,
        PreferenceSections::HubSignupPageSection.new,
        PreferenceSections::GroupSignupPageSection.new,
        PreferenceSections::MainLinksSection.new,
        PreferenceSections::FooterAndExternalLinksSection.new,
        PreferenceSections::UserGuideSection.new,
        PreferenceSections::MapSection.new
      ]
    end
  end
end
