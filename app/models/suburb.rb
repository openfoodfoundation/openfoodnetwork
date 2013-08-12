class Suburb < ActiveRecord::Base
  belongs_to :state, :class_name => Spree::State

  delegate :name, to: :state, prefix: true

  scope :matching , ->(term) {
    where("lower(name) like ? or cast(postcode as text) like ?", "%#{term.to_s.downcase}%", "%#{term}%")
  }
end
