object @image
attributes(*image_attributes)
attributes :viewable_type, :viewable_id
node( :thumb_url ) { @product.images.first.attachment.url(:mini) }
node( :image_url ) { @product.images.first.attachment.url(:product) }
