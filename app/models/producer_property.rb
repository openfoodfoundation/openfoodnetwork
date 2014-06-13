class ProducerProperty < ActiveRecord::Base
  belongs_to :property, class_name: 'Spree::Property'
end
