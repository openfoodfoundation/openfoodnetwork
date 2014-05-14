class EnterpriseRelationship < ActiveRecord::Base
  belongs_to :parent, class_name: 'Enterprise'
  belongs_to :child, class_name: 'Enterprise'

  validates_presence_of :parent_id, :child_id
  validates_uniqueness_of :child_id, scope: :parent_id
end
