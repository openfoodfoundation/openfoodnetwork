# frozen_string_literal: true

module Spree
  class Zone < ApplicationRecord
    has_many :zone_members, dependent: :destroy, class_name: "Spree::ZoneMember", inverse_of: :zone
    has_many :tax_rates, dependent: :destroy, inverse_of: :zone
    has_many :spree_shipping_method_zones, class_name: 'Spree::ShippingMethodZone',
                                           dependent: :destroy
    has_many :shipping_methods, through: :spree_shipping_method_zones

    validates :name, presence: true, uniqueness: true
    after_save :remove_defunct_members
    after_save :remove_previous_default

    alias :members :zone_members
    accepts_nested_attributes_for :zone_members, allow_destroy: true,
                                                 reject_if: proc { |a| a['zoneable_id'].blank? }

    def kind
      return unless members.any? && members.none? { |member| member.try(:zoneable_type).nil? }

      members.last.zoneable_type.demodulize.underscore
    end

    def kind=(value)
      # do nothing - just here to satisfy the form
    end

    def contains_address?(address)
      return false unless address

      members.any? do |zone_member|
        case zone_member.zoneable_type
        when 'Spree::Country'
          zone_member.zoneable_id == address.country_id
        when 'Spree::State'
          zone_member.zoneable_id == address.state_id
        else
          false
        end
      end
    end

    # Returns the matching zone with the highest priority zone type (State, Country, Zone.)
    # Returns nil in the case of no matches.
    def self.match(address)
      return unless matches = includes(:zone_members).
        order('zone_members_count', 'created_at').
        select { |zone| zone.contains_address? address }

      ['state', 'country'].each do |zone_kind|
        if match = matches.detect { |zone| zone_kind == zone.kind }
          return match
        end
      end
      matches.first
    end

    # convenience method for returning the countries contained within a zone
    def countries
      @countries ||= case kind
                     when 'country' then zoneables
                     when 'state' then zoneables.collect(&:country)
                     end.flatten.compact.uniq
    end

    def <=>(other)
      name <=> other.name
    end

    # All zoneables belonging to the zone members.  Will be a collection of either
    # countries or states depending on the zone type.
    def zoneables
      members.collect(&:zoneable)
    end

    def country_ids
      if kind == 'country'
        members.collect(&:zoneable_id)
      else
        []
      end
    end

    def state_ids
      if kind == 'state'
        members.collect(&:zoneable_id)
      else
        []
      end
    end

    def country_ids=(ids)
      zone_members.destroy_all
      ids.reject(&:blank?).map do |id|
        member = ZoneMember.new
        member.zoneable_type = 'Spree::Country'
        member.zoneable_id = id
        members << member
      end
    end

    def state_ids=(ids)
      zone_members.destroy_all
      ids.reject(&:blank?).map do |id|
        member = ZoneMember.new
        member.zoneable_type = 'Spree::State'
        member.zoneable_id = id
        members << member
      end
    end

    def self.default_tax
      find_by(default_tax: true)
    end

    # Indicates whether the specified zone falls entirely within the zone performing
    # the check.
    def contains?(target)
      return false if kind == 'state' && target.kind == 'country'
      return false if zone_members.empty? || target.zone_members.empty?

      if kind == target.kind
        if target.zoneables.any? { |target_zoneable| zoneables.exclude?(target_zoneable) }
          return false
        end
      elsif target.zoneables.any? { |target_state| zoneables.exclude?(target_state.country) }
        return false
      end
      true
    end

    private

    def remove_defunct_members
      return unless zone_members.any?

      zone_members.where('zoneable_id IS NULL OR zoneable_type != ?',
                         "Spree::#{kind.capitalize}").destroy_all
    end

    def remove_previous_default
      Spree::Zone.where('id != ?', id).update_all(default_tax: false) if default_tax
    end
  end
end
