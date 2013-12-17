module Spree
  class VariantSerializer < ActiveModel::Serializer
    attributes :id, :is_master, :count_on_hand, :options_text
    has_many :images
  end
end

