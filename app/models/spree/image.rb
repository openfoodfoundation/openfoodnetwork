# frozen_string_literal: true

require 'spree/core/s3_support'

module Spree
  class Image < Asset
    validates_attachment_presence :attachment
    validate :no_attachment_errors

    # This is where the styles are used in the app:
    # - mini: used in the BackOffice: Bulk Product Edit page and Order Cycle edit page
    # - small: used in the FrontOffice: Product List page
    # - product: used in the BackOffice: Product Image upload modal in the Bulk Product Edit page
    #                                      and Product image edit page
    # - large: used in the FrontOffice: product modal
    has_attached_file :attachment,
                      styles: { mini: "48x48#", small: "227x227#",
                                product: "240x240>", large: "600x600>" },
                      default_style: :product,
                      url: '/spree/products/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/products/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

    # save the w,h of the original image (from which others can be calculated)
    # we need to look at the write-queue for images which have not been saved yet
    after_post_process :find_dimensions

    include Spree::Core::S3Support
    supports_s3 :attachment

    # used by admin products autocomplete
    def mini_url
      attachment.url(:mini, false)
    end

    def find_dimensions
      return if attachment.errors.present?

      geometry = Paperclip::Geometry.from_file(local_filename_of_original)

      self.attachment_width  = geometry.width
      self.attachment_height = geometry.height
    end

    def local_filename_of_original
      temporary = attachment.queued_for_write[:original]

      if temporary&.path.present?
        temporary.path
      else
        attachment.path
      end
    end

    # if there are errors from the plugin, then add a more meaningful message
    def no_attachment_errors
      return if attachment.errors.empty?

      if errors.all? { |e| e.type == "Paperclip::Errors::NotIdentifiedByImageMagickError" }
        attachment.errors.clear
        errors.add :base, I18n.t('spree.admin.products.image_upload_error')
      else
        errors.add :attachment,
                   I18n.t('spree.admin.products.paperclip_image_error', attachment_file_name: attachment_file_name)
      end
      false
    end

    def self.set_attachment_attribute(attribute_name, attribute_value)
      attachment_definitions[:attachment][attribute_name] = attribute_value
    end

    def self.set_storage_attachment_attributes
      if Spree::Config[:use_s3]
        set_s3_attachment_attributes
      else
        attachment_definitions[:attachment].delete(:storage)
      end
    end

    def self.set_s3_attachment_attributes
      set_attachment_attribute(:storage, :s3)
      set_attachment_attribute(:s3_credentials, s3_credentials)
      set_attachment_attribute(:s3_headers,
                               ActiveSupport::JSON.decode(Spree::Config[:s3_headers]))
      set_attachment_attribute(:bucket, Spree::Config[:s3_bucket])

      # We use :s3_alias_url (virtual host url style) and set the URL on property s3_host_alias
      set_attachment_attribute(:s3_host_alias, attachment_definitions[:attachment][:url])
      set_attachment_attribute(:url, ":s3_alias_url")
    end
    private_class_method :set_s3_attachment_attributes

    def self.s3_credentials
      { access_key_id: Spree::Config[:s3_access_key],
        secret_access_key: Spree::Config[:s3_secret],
        bucket: Spree::Config[:s3_bucket] }
    end
    private_class_method :s3_credentials
  end
end
