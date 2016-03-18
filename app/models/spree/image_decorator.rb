Spree::Image.class_eval do
  after_save :refresh_products_cache
  after_destroy :refresh_products_cache

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
    Spree::Image.attachment_definitions[:attachment][:styles] =
      format_styles(Spree::Image.attachment_definitions[:attachment][:styles])
  end

  reformat_styles


  private

  def refresh_products_cache
    viewable.try :refresh_products_cache
  end
end
