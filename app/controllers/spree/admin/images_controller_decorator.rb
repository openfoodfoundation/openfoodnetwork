Spree::Admin::ImagesController.class_eval do
  # This will make resource controller redirect correctly after deleting product images.
  # This can be removed after upgrading to Spree 2.1.
  # See here https://github.com/spree/spree/commit/334a011d2b8e16355e4ae77ae07cd93f7cbc8fd1
  belongs_to 'spree/product', find_by: :permalink
end
