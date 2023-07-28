# frozen_string_literal: true

class EnterpriseRelationship < ApplicationRecord
  belongs_to :parent, class_name: 'Enterprise', touch: true
  belongs_to :child, class_name: 'Enterprise', touch: true
  has_many :permissions, class_name: 'EnterpriseRelationshipPermission', dependent: :destroy

  validates :child_id, uniqueness: {
    scope: :parent_id,
    message: I18n.t('validation_msg_relationship_already_established')
  }

  before_destroy :revoke_all_child_variant_overrides
  before_destroy :destroy_related_exchanges
  after_save :update_permissions_of_child_variant_overrides

  scope :with_enterprises, -> {
    joins("
      LEFT JOIN enterprises AS parent_enterprises
        ON parent_enterprises.id = enterprise_relationships.parent_id").
      joins("
        LEFT JOIN enterprises AS child_enterprises
          ON child_enterprises.id = enterprise_relationships.child_id")
  }

  scope :involving_enterprises, ->(enterprises) {
    where('parent_id IN (?) OR child_id IN (?)', enterprises.select(&:id), enterprises.select(&:id))
  }

  scope :permitting, ->(enterprise_ids) { where('child_id IN (?)', enterprise_ids) }
  scope :permitted_by, ->(enterprise_ids) { where('parent_id IN (?)', enterprise_ids) }

  scope :with_permission, ->(permission) {
    joins(:permissions).
      where('enterprise_relationship_permissions.name = ?', permission)
  }

  scope :by_name, -> { with_enterprises.order('child_enterprises.name, parent_enterprises.name') }

  # Load an array of the relatives of each enterprise (ie. any enterprise related to it in
  # either direction). This array is split into distributors and producers, and has the format:
  # {enterprise_id => {distributors: [id, ...], producers: [id, ...]} }
  def self.relatives(activated_only = false)
    relationships = EnterpriseRelationship.includes(:child, :parent)
    relatives = {}

    Enterprise.is_primary_producer.pluck(:id).each do |enterprise_id|
      relatives[enterprise_id] ||= { distributors: Set.new, producers: Set.new }
      relatives[enterprise_id][:producers] << enterprise_id
    end
    Enterprise.is_distributor.pluck(:id).each do |enterprise_id|
      relatives[enterprise_id] ||= { distributors: Set.new, producers: Set.new }
      relatives[enterprise_id][:distributors] << enterprise_id
    end

    relationships.each do |r|
      relatives[r.parent_id] ||= { distributors: Set.new, producers: Set.new }
      relatives[r.child_id]  ||= { distributors: Set.new, producers: Set.new }

      if !activated_only || r.child.activated?
        relatives[r.parent_id][:producers]    << r.child_id if r.child.is_primary_producer
        relatives[r.parent_id][:distributors] << r.child_id if r.child.is_distributor
      end

      if !activated_only || r.parent.activated?
        relatives[r.child_id][:producers]    << r.parent_id if r.parent.is_primary_producer
        relatives[r.child_id][:distributors] << r.parent_id if r.parent.is_distributor
      end
    end

    relatives
  end

  def permissions_list=(perms)
    if perms.nil?
      permissions.destroy_all
    else
      permissions.where('name NOT IN (?)', perms).destroy_all
      perms.map { |name| permissions.find_or_initialize_by name: name }
    end
  end

  def has_permission?(name)
    permissions.reload.map(&:name).map(&:to_sym).include? name.to_sym
  end

  private

  def update_permissions_of_child_variant_overrides
    if has_permission?(:create_variant_overrides)
      allow_all_child_variant_overrides
    else
      revoke_all_child_variant_overrides
    end
  end

  def allow_all_child_variant_overrides
    child_variant_overrides.update_all(permission_revoked_at: nil)
  end

  def revoke_all_child_variant_overrides
    child_variant_overrides.update_all(permission_revoked_at: Time.zone.now)
  end

  def destroy_related_exchanges
    Exchange.where(sender: parent, receiver: child, incoming: true).destroy_all
  end

  def child_variant_overrides
    VariantOverride.unscoped.for_hubs(child)
      .joins(variant: :product).where("spree_products.supplier_id IN (?)", parent)
  end
end
