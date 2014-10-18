module Admin
  module ImageSettingsHelper
    def admin_image_settings_format_options
      [['Unchanged', ''], ['PNG', 'png'], ['JPEG', 'jpg']]
    end

    def admin_image_settings_geometry_from_style(style)
      geometry, format = admin_image_settings_split_style style
      geometry
    end

    def admin_image_settings_format_from_style(style)
      geometry, format = admin_image_settings_split_style style
      format
    end

    def admin_image_settings_split_style(style)
      [style, nil].flatten[0..1]
    end
  end
end
