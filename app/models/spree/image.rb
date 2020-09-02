# frozen_string_literal: true

module Spree
  class Image < Asset
    validates_attachment_presence :attachment
    validate :no_attachment_errors

    has_attached_file :attachment,
                      styles: { mini: '48x48>', small: '100x100>',
                                product: '240x240>', large: '600x600>' },
                      default_style: :product,
                      url: '/spree/products/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/products/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -colorspace RGB' }

    # save the w,h of the original image (from which others can be calculated)
    # we need to look at the write-queue for images which have not been saved yet
    after_post_process :find_dimensions

    include Spree::Core::S3Support
    supports_s3 :attachment

    Spree::Image.attachment_definitions[:attachment][:styles] =
      ActiveSupport::JSON.decode(Spree::Config[:attachment_styles]).symbolize_keys!
    Spree::Image.attachment_definitions[:attachment][:path] = Spree::Config[:attachment_path]
    Spree::Image.attachment_definitions[:attachment][:url] = Spree::Config[:attachment_url]
    Spree::Image.attachment_definitions[:attachment][:default_url] =
      Spree::Config[:attachment_default_url]
    Spree::Image.attachment_definitions[:attachment][:default_style] =
      Spree::Config[:attachment_default_style]

    # used by admin products autocomplete
    def mini_url
      attachment.url(:mini, false)
    end

    def find_dimensions
      temporary = attachment.queued_for_write[:original]
      filename = temporary.path unless temporary.nil?
      filename = attachment.path if filename.blank?
      geometry = Paperclip::Geometry.from_file(filename)
      self.attachment_width  = geometry.width
      self.attachment_height = geometry.height
    end

    # if there are errors from the plugin, then add a more meaningful message
    def no_attachment_errors
      return if attachment.errors.empty?

      errors.add :attachment, "Paperclip returned errors for file '#{attachment_file_name}' - check ImageMagick installation or image source file."
      false
    end

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
  end
end
