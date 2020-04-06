require 'spree/core/s3_support'

Spree::Image.class_eval do
  include Spree::Core::S3Support
  #supports_s3 :attachment

  #Spree::Image.attachment_definitions[:attachment][:styles] = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles]).symbolize_keys!
  #Spree::Image.attachment_definitions[:attachment][:path] = Spree::Config[:attachment_path]
  #Spree::Image.attachment_definitions[:attachment][:url] = Spree::Config[:attachment_url]
  #Spree::Image.attachment_definitions[:attachment][:default_url] = Spree::Config[:attachment_default_url]
  #Spree::Image.attachment_definitions[:attachment][:default_style] = Spree::Config[:attachment_default_style]

  # Spree stores attachent definitions in JSON. This converts the style name and format to
  # strings. However, when paperclip encounters these, it doesn't recognise the format.
  # Here we solve that problem by converting format and style name to symbols.
  # See also: ImageSettingsController decorator.
  #
  # eg. {'mini' => ['48x48>', 'png']} is converted to {mini: ['48x48>', :png]}
  def self.format_styles(styles)
    styles_a = styles.map do |name, style|
      style[1] = style[1].to_sym if style.is_a? Array
      [name.to_sym, style]
    end

    Hash[styles_a]
  end

  def self.reformat_styles
    #Spree::Image.attachment_definitions[:attachment][:styles] =
    #  format_styles(Spree::Image.attachment_definitions[:attachment][:styles])
  end

  reformat_styles
end
