# frozen_string_literal: true

require "tasks/sample_data/logging"

module SampleData
  class PermissionFactory
    include Logging

    def create_samples(enterprises)
      all_permissions = [
        :add_to_order_cycle,
        :manage_products,
        :edit_profile,
        :create_variant_overrides
      ]
      enterprises.each do |enterprise|
        log "#{enterprise.name} permits everybody to do everything."
        enterprise_permits_to(enterprise, enterprises, all_permissions)
      end
    end

    private

    def enterprise_permits_to(enterprise, receivers, permissions)
      receivers.each do |receiver|
        EnterpriseRelationship.where(
          parent_id: enterprise,
          child_id: receiver
        ).first_or_create!(
          parent: enterprise,
          child: receiver,
          permissions_list: permissions
        )
      end
    end
  end
end
