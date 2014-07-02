class EnterpriseRelationship < ActiveRecord::Base
  belongs_to :parent, class_name: 'Enterprise', touch: true
  belongs_to :child, class_name: 'Enterprise', touch: true

  validates_presence_of :parent_id, :child_id
  validates_uniqueness_of :child_id, scope: :parent_id, message: "^That relationship is already established."

  scope :with_enterprises,
    joins('LEFT JOIN enterprises AS parent_enterprises ON parent_enterprises.id = enterprise_relationships.parent_id').
    joins('LEFT JOIN enterprises AS child_enterprises ON child_enterprises.id = enterprise_relationships.child_id')
  scope :by_name, with_enterprises.order('parent_enterprises.name, child_enterprises.name')

  scope :involving_enterprises, ->(enterprises) {
    where('parent_id IN (?) OR child_id IN (?)', enterprises, enterprises)
  }
end
