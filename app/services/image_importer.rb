# frozen_string_literal: true

class ImageImporter
  def import(url, product)
    valid_url = URI.parse(url)
    file = open(valid_url.to_s)
    filename = File.basename(valid_url.path)

    Spree::Image.create(
      attachment: { io: file, filename: filename },
      viewable_id: product.id,
      viewable_type: Spree::Product,
    )
  end
end
