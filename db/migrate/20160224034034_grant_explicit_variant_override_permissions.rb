class GrantExplicitVariantOverridePermissions < ActiveRecord::Migration
  def up
    hubs = Enterprise.is_distributor

    begin
      EnterpriseRelationship.skip_callback :save, :after, :apply_variant_override_permissions

      hubs.each do |hub|
        next if hub.owner.admin?
        explicitly_granting_producer_ids = hub.relationships_as_child
          .with_permission(:create_variant_overrides).map(&:parent_id)

        managed_producer_ids = Enterprise.managed_by(hub.owner).is_primary_producer.pluck(:id)
        implicitly_granting_producer_ids = managed_producer_ids - explicitly_granting_producer_ids - [hub.id]

        # create explicit VO permissions for producers currently granting implicit permission
        Enterprise.where(id: implicitly_granting_producer_ids).each do |producer|
          relationship = producer.relationships_as_parent.find_or_initialize_by_child_id(hub.id)
          permission = relationship.permissions.find_or_initialize_by_name(:create_variant_overrides)
          relationship.save! unless permission.persisted?
        end
      end
    ensure
      EnterpriseRelationship.set_callback :save, :after, :apply_variant_override_permissions
    end
  end

  def down
  end
end
