# frozen_string_literal: true

module Spree
  class Address < ApplicationRecord
    include AddressDisplay

    searchable_attributes :firstname, :lastname, :phone, :full_name, :full_name_reversed,
                          :full_name_with_comma, :full_name_with_comma_reversed
    searchable_associations :country, :state

    belongs_to :country, class_name: "Spree::Country"
    belongs_to :state, class_name: "Spree::State", optional: true

    has_one :enterprise, dependent: :restrict_with_exception
    has_many :shipments, dependent: :restrict_with_exception

    validates :address1, :city, :phone, presence: true
    validates :company, presence: true, unless: -> { first_name.blank? || last_name.blank? }
    validates :firstname, :lastname, presence: true, if: -> do
      company.blank? || company == 'unused'
    end
    validates :zipcode, presence: true, if: :require_zipcode?

    validate :state_validate

    after_save :touch_enterprise

    alias_attribute :first_name, :firstname
    alias_attribute :last_name, :lastname
    delegate :name, to: :state, prefix: true, allow_nil: true

    ransacker :full_name, formatter: proc { |value| value.to_s } do |parent|
      Arel::Nodes::SqlLiteral.new(
        "CONCAT(#{parent.table_name}.firstname, ' ', #{parent.table_name}.lastname)"
      )
    end

    ransacker :full_name_reversed, formatter: proc { |value| value.to_s } do |parent|
      Arel::Nodes::SqlLiteral.new(
        "CONCAT(#{parent.table_name}.lastname, ' ', #{parent.table_name}.firstname)"
      )
    end

    ransacker :full_name_with_comma, formatter: proc { |value| value.to_s } do |parent|
      Arel::Nodes::SqlLiteral.new(
        "CONCAT(#{parent.table_name}.firstname, ', ', #{parent.table_name}.lastname)"
      )
    end

    ransacker :full_name_with_comma_reversed, formatter: proc { |value| value.to_s } do |parent|
      Arel::Nodes::SqlLiteral.new(
        "CONCAT(#{parent.table_name}.lastname, ', ', #{parent.table_name}.firstname)"
      )
    end

    def self.default
      new(country: DefaultCountry.country)
    end

    def full_name
      "#{firstname} #{lastname}".strip
    end

    def state_text
      state.try(:abbr) || state.try(:name) || state_name
    end

    def same_as?(other)
      return false if other.nil?

      attributes.except('id', 'updated_at', 'created_at') ==
        other.attributes.except('id', 'updated_at', 'created_at')
    end

    alias same_as same_as?

    def to_s
      "#{full_name}: #{address1}"
    end

    def clone
      self.class.new(attributes.except('id', 'updated_at', 'created_at'))
    end

    def ==(other)
      self_attrs = attributes
      other_attrs = other.respond_to?(:attributes) ? other.attributes : {}

      [self_attrs, other_attrs].each { |attrs|
        attrs.except!('id', 'created_at', 'updated_at', 'order_id')
      }

      self_attrs == other_attrs
    end

    def empty?
      attributes.except('id', 'created_at', 'updated_at', 'order_id', 'country_id').all? { |_, v|
        v.nil?
      }
    end

    # Generates an ActiveMerchant compatible address hash
    def active_merchant_hash
      {
        name: full_name,
        address1:,
        address2:,
        city:,
        state: state_text,
        zip: zipcode,
        country: country.try(:iso),
        phone:
      }
    end

    def full_address
      render_address([address1, address2, city, zipcode, state&.name])
    end

    def address_part1
      render_address([address1, address2])
    end

    def address_part2
      render_address([city, zipcode, state&.name])
    end

    def address_and_city
      [address1, address2, city].compact_blank.join(' ')
    end

    private

    def require_zipcode?
      true
    end

    def state_validate
      # Skip state validation without country (also required)
      # or when disabled by preference
      return if country.blank? || !Spree::Config[:address_requires_state]
      return unless country.states_required

      # Ensure associated state belongs to country
      if state.present?
        if state.country == country
          self.state_name = nil # not required as we have a valid state and country combo
        elsif state_name.present?
          self.state = nil
        else
          errors.add(:state, :invalid)
        end
      end

      # Ensure state_name belongs to country without states,
      #   or that it matches a predefined state name/abbr
      if state_name.present? && country.states.present?
        states = country.states.find_all_by_name_or_abbr(state_name)

        if states.size == 1
          self.state = states.first
          self.state_name = nil
        else
          errors.add(:state, :invalid)
        end
      end

      # ensure at least one state field is populated
      return unless state.blank? && state_name.blank?

      errors.add :state, :blank
      errors.add :state_id, :blank
    end

    def touch_enterprise
      return unless enterprise&.persisted?

      enterprise.touch
    end

    def render_address(parts)
      parts.compact_blank.join(', ')
    end
  end
end
