# frozen_string_literal: true

module Spree
  class Image < Asset
    has_one_attached :attachment, service: image_service do |attachment|
      attachment.variant :mini, resize_to_fill: [48, 48]
      attachment.variant :small, resize_to_fill: [227, 227]
      attachment.variant :product, resize_to_limit: [240, 240]
      attachment.variant :large, resize_to_limit: [600, 600]
    end

    validates :attachment,
              attached: true,
              processable_image: true,
              content_type: %r{\Aimage/(png|jpeg|gif|jpg|svg\+xml|webp)\Z}
    validate :no_attachment_errors

    def variant(name)
      if attachment.variable?
        attachment.variant(name)
      else
        attachment
      end
    end

    def url(size)
      return unless attachment.attached?
      return variant(size).processed.url if attachment.service.name == :amazon_public

      url_for(variant(size))
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
  end
end
