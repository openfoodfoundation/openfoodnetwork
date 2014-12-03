Spree::Admin::ImageSettingsController.class_eval do
  # Spree stores attachent definitions in JSON. This converts the style name and format to
  # strings. However, when paperclip encounters these, it doesn't recognise the format.
  # Here we solve that problem by converting format and style name to symbols.
  def update_paperclip_settings_with_format_styles
    update_paperclip_settings_without_format_styles
    Spree::Image.reformat_styles
  end

  alias_method_chain :update_paperclip_settings, :format_styles
end
