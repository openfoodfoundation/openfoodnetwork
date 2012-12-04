class VariantPresenter
  attr_accessor :variant

  def initialize(variant)
    @variant = variant
  end

  delegate :id, :to => :variant

  def image_url
    @variant.images.first.attachment.url :mini if @variant.images.present?
  end
end
