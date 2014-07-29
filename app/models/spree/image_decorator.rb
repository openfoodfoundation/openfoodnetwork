Spree::Image.class_eval do
  has_attached_file :attachment,
      :styles => { :mini => '48x48>', :small => '114x114#', :product => '240x240>', :large => '600x600>' },
      :default_style => :product,
      :url => '/spree/products/:id/:style/:basename.:extension',
      :path => ':rails_root/public/spree/products/:id/:style/:basename.:extension',
      :convert_options => { :all => '-strip -auto-orient -quality 75' }
end
