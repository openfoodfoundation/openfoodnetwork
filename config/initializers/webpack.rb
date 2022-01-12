
module WebpackImageExtension
  def image_pack_path(image)
    # The Webpacker::Helper#resolve_path_to_image method is incredibly useful
    # for nicely fetching Webpacker image paths, but it's private.
    resolve_path_to_image(image)
  end
end

Webpacker::Helper.include WebpackImageExtension
