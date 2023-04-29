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
        if value.is_a?(ActionDispatch::Http::UploadedFile)
          blob = store_file(value)
          update_preference("#{name}_blob_id", blob.id)
        else
          update_preference(name, value)
        end
      end

      ContentConfig.updated_at = Time.zone.now

      flash[:success] =
        t(:successfully_updated, resource: I18n.t('admin.contents.edit.your_content'))

      redirect_to main_app.edit_admin_contents_path
    end

    private

    def store_file(attachable)
      ActiveStorage::Blob.create_and_upload!(
        io: attachable.open,
        filename: attachable.original_filename,
        content_type: attachable.content_type,
        service_name: :local,
        identify: false,
      )
    end

    def update_preference(name, value)
      return unless ContentConfig.has_preference?(name)

      ContentConfig.public_send("#{name}=", value)
    end

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
