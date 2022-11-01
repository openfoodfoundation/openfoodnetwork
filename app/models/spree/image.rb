# frozen_string_literal: true

module Spree
  class Image < Asset
    SIZES = {
      mini: { resize_to_fill: [48, 48] },
      small: { resize_to_fill: [227, 227] },
      product: { resize_to_limit: [240, 240] },
      large: { resize_to_limit: [600, 600] },
    }.freeze

    self.ignored_columns = %i(attachment_file_name
                              attachment_content_type
                              attachment_file_size
                              attachment_updated_at
                              attachment_width
                              attachment_height)

    has_one_attached :attachment

    validates :attachment, attached: true, content_type: %r{\Aimage/(png|jpeg|gif|jpg|svg\+xml|webp)\Z}
    validate :no_attachment_errors

    def variant(name)
      if attachment.variable?
        attachment.variant(SIZES[name])
      else
        attachment
      end
    end

    def url(size)
      return unless attachment.attached?

      Rails.application.routes.url_helpers.url_for(variant(size))
    end

    def cdn_url(size)
      return url(size) unless cdn_activated?

      return unless attachment.attached?

      variant(size).blob.url
    end

    # if there are errors from the plugin, then add a more meaningful message
    def no_attachment_errors
      return if errors[:attachment].empty?

      if errors.all? { |e| e.type == :content_type_invalid }
        attachment.errors.clear
        errors.add :base, I18n.t('spree.admin.products.image_upload_error')
      end

      false
    end

    def cdn_activated?
      Rails.application.config.active_storage.service != :local
    end
  end
end
