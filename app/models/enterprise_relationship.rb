class EnterpriseRelationship < ActiveRecord::Base
  belongs_to :parent, class_name: 'Enterprise', touch: true
  belongs_to :child, class_name: 'Enterprise', touch: true
  has_many :permissions, class_name: 'EnterpriseRelationshipPermission'

  validates_presence_of :parent_id, :child_id
  validates_uniqueness_of :child_id, scope: :parent_id, message: "^That relationship is already established."

  scope :with_enterprises,
    joins('LEFT JOIN enterprises AS parent_enterprises ON parent_enterprises.id = enterprise_relationships.parent_id').
    joins('LEFT JOIN enterprises AS child_enterprises ON child_enterprises.id = enterprise_relationships.child_id')

  scope :involving_enterprises, ->(enterprises) {
    where('parent_id IN (?) OR child_id IN (?)', enterprises, enterprises)
  }

  scope :permitting, ->(enterprises) { where('child_id IN (?)', enterprises) }

  scope :with_permission, ->(permission) {
    joins(:permissions).
    where('enterprise_relationship_permissions.name = ?', permission)
  }

  scope :by_name, with_enterprises.order('child_enterprises.name, parent_enterprises.name')


  def permissions_list=(perms)
    perms.andand.each { |name| permissions.build name: name }
  end
end
