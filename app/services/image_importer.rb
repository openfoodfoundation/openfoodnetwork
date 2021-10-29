# frozen_string_literal: true

class ImageImporter
  def import(url, product)
    attach(download(url), product)
  end

  private

  def download(url)
    local_file = Tempfile.new
    remote_file = open(url)
    IO.copy_stream(remote_file, local_file)
    local_file
  end

  def attach(file, product)
    Spree::Image.create(
      attachment: file,
      viewable_id: product.master.id,
      viewable_type: Spree::Variant,
    )
  end
end
