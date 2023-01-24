# frozen_string_literal: true

require 'spec_helper'

describe Spree::Preferences::Preferable do
  before :all do
    class A
      include Spree::Preferences::Preferable
      attr_reader :id

      def initialize
        @id = rand(999)
      end

      preference :color, :string, default: 'green', description: "My Favorite Color"
    end

    class B < A
      preference :flavor, :string
    end
  end

  before :each do
    @a = A.new
    allow(@a).to receive_messages(persisted?: true)
    @b = B.new
    allow(@b).to receive_messages(persisted?: true)

    # ensure we're persisting as that is the default
    #
    store = Spree::Preferences::Store.instance
    store.persistence = true
  end

  describe "preference definitions" do
    it "parent should not see child definitions" do
      expect(@a.has_preference?(:color)).to be_truthy
      expect(@a.has_preference?(:flavor)).not_to be_truthy
    end

    it "child should have parent and own definitions" do
      expect(@b.has_preference?(:color)).to be_truthy
      expect(@b.has_preference?(:flavor)).to be_truthy
    end

    it "instances have defaults" do
      expect(@a.preferred_color).to eq 'green'
      expect(@b.preferred_color).to eq 'green'
      expect(@b.preferred_flavor).to be_nil
    end

    it "can be asked if it has a preference definition" do
      expect(@a.has_preference?(:color)).to be_truthy
      expect(@a.has_preference?(:bad)).to be_falsy
    end

    it "can be asked and raises" do
      expect {
        @a.has_preference! :flavor
      }.to raise_error(NoMethodError, "flavor preference not defined")
    end

    it "has a type" do
      expect(@a.preferred_color_type).to eq :string
      expect(@a.preference_type(:color)).to eq :string
    end

    it "has a default" do
      expect(@a.preferred_color_default).to eq 'green'
      expect(@a.preference_default(:color)).to eq 'green'
    end

    it "has a description" do
      expect(@a.preferred_color_description).to eq "My Favorite Color"
      expect(@a.preference_description(:color)).to eq "My Favorite Color"
    end

    it "raises if not defined" do
      expect {
        @a.get_preference :flavor
      }.to raise_error(NoMethodError, "flavor preference not defined")
    end
  end

  describe "preference access" do
    it "handles ghost methods for preferences" do
      @a.preferred_color = 'blue'
      expect(@a.preferred_color).to eq 'blue'

      @a.prefers_color = 'green'
      expect(@a.prefers_color?).to eq 'green'
    end

    it "has genric readers" do
      @a.preferred_color = 'red'
      expect(@a.prefers?(:color)).to eq 'red'
      expect(@a.preferred(:color)).to eq 'red'
    end

    it "parent and child instances have their own prefs" do
      @a.preferred_color = 'red'
      @b.preferred_color = 'blue'

      expect(@a.preferred_color).to eq 'red'
      expect(@b.preferred_color).to eq 'blue'
    end

    it "raises when preference not defined" do
      expect {
        @a.set_preference(:bad, :bone)
      }.to raise_exception(NoMethodError, "bad preference not defined")
    end

    it "builds a hash of preferences" do
      @b.preferred_flavor = :strawberry
      expect(@b.preferences[:flavor]).to eq 'strawberry'
      expect(@b.preferences[:color]).to eq 'green' # default from A
    end

    context "database fallback" do
      before do
        @a.instance_variable_set("@pending_preferences", {})
      end

      it "retrieves a preference from the database before falling back to default" do
        preference = double(value: "chatreuse", key: 'a/color/123')
        expect(Spree::Preference).to receive(:find_by).and_return(preference)
        expect(@a.preferred_color).to eq 'chatreuse'
      end

      it "defaults if no database key exists" do
        expect(Spree::Preference).to receive(:find_by).and_return(nil)
        expect(@a.preferred_color).to eq 'green'
      end
    end

    context "converts integer preferences to integer values" do
      before do
        A.preference :is_integer, :integer
      end

      it "with strings" do
        @a.set_preference(:is_integer, '3')
        expect(@a.preferences[:is_integer]).to eq 3

        @a.set_preference(:is_integer, '')
        expect(@a.preferences[:is_integer]).to eq 0
      end
    end

    context "converts decimal preferences to BigDecimal values" do
      before do
        A.preference :if_decimal, :decimal
      end

      it "returns a BigDecimal" do
        @a.set_preference(:if_decimal, 3.3)
        expect(@a.preferences[:if_decimal].class).to eq BigDecimal
      end

      it "with strings" do
        @a.set_preference(:if_decimal, '3.3')
        expect(@a.preferences[:if_decimal]).to eq 3.3

        @a.set_preference(:if_decimal, '')
        expect(@a.preferences[:if_decimal]).to eq 0.0
      end

      context "when the value cannot be converted to BigDecimal" do
        it "returns the original value" do
          @a.set_preference(:if_decimal, "invalid")
          expect(@a.preferences[:if_decimal]).to eq "invalid"
        end
      end
    end

    context "converts boolean preferences to boolean values" do
      before do
        A.preference :is_boolean, :boolean, default: true
      end

      it "with strings" do
        @a.set_preference(:is_boolean, '0')
        expect(@a.preferences[:is_boolean]).to be_falsy
        @a.set_preference(:is_boolean, 'f')
        expect(@a.preferences[:is_boolean]).to be_falsy
        @a.set_preference(:is_boolean, 't')
        expect(@a.preferences[:is_boolean]).to be_truthy
      end

      it "with integers" do
        @a.set_preference(:is_boolean, 0)
        expect(@a.preferences[:is_boolean]).to be_falsy
        @a.set_preference(:is_boolean, 1)
        expect(@a.preferences[:is_boolean]).to be_truthy
      end

      it "with an empty string" do
        @a.set_preference(:is_boolean, '')
        expect(@a.preferences[:is_boolean]).to be_falsy
      end

      it "with an empty hash" do
        @a.set_preference(:is_boolean, [])
        expect(@a.preferences[:is_boolean]).to be_falsy
      end
    end

    context "converts any preferences to any values" do
      before do
        A.preference :product_ids, :any, default: []
        A.preference :product_attributes, :any, default: {}
      end

      it "with array" do
        expect(@a.preferences[:product_ids]).to eq []
        @a.set_preference(:product_ids, [1, 2])
        expect(@a.preferences[:product_ids]).to eq [1, 2]
      end

      it "with hash" do
        expect(@a.preferences[:product_attributes]).to eq({})
        @a.set_preference(:product_attributes, { id: 1, name: 2 })
        attributes_hash = { id: 1, name: 2 }
        expect(@a.preferences[:product_attributes]).to eq attributes_hash
      end
    end
  end

  describe "persisted preferables" do
    before(:all) do
      class CreatePrefTest < ActiveRecord::Migration[4.2]
        def self.up
          create_table :pref_tests do |t|
            t.string :col
          end
        end

        def self.down
          drop_table :pref_tests
        end
      end

      @migration_verbosity = ActiveRecord::Migration.verbose
      ActiveRecord::Migration.verbose = false
      CreatePrefTest.migrate(:up)

      class PrefTest < ApplicationRecord
        preference :pref_test_pref, :string, default: 'abc'
        preference :pref_test_any, :any, default: []
      end
    end

    after(:all) do
      CreatePrefTest.migrate(:down)
      ActiveRecord::Migration.verbose = @migration_verbosity
    end

    before(:each) do
      @pt = PrefTest.create
    end

    describe "pending preferences for new activerecord objects" do
      it "saves preferences after record is saved" do
        pr = PrefTest.new
        pr.set_preference(:pref_test_pref, 'XXX')
        expect(pr.get_preference(:pref_test_pref)).to eq 'XXX'
        pr.save!
        expect(pr.get_preference(:pref_test_pref)).to eq 'XXX'
      end

      it "saves preferences for serialized object" do
        pr = PrefTest.new
        pr.set_preference(:pref_test_any, [1, 2])
        expect(pr.get_preference(:pref_test_any)).to eq [1, 2]
        pr.save!
        expect(pr.get_preference(:pref_test_any)).to eq [1, 2]
      end
    end

    describe "requires a valid id" do
      it "for cache_key" do
        pref_test = PrefTest.new
        expect(pref_test.preference_cache_key(:pref_test_pref)).to be_nil

        pref_test.save
        expect(pref_test.preference_cache_key(:pref_test_pref)).to_not be_nil
      end

      it "but returns default values" do
        pref_test = PrefTest.new
        expect(pref_test.get_preference(:pref_test_pref)).to eq 'abc'
      end

      it "adds prefs in a pending hash until after_create" do
        pref_test = PrefTest.new
        expect(pref_test).to receive(:add_pending_preference).with(:pref_test_pref, 'XXX')
        pref_test.set_preference(:pref_test_pref, 'XXX')
      end
    end

    it "clear preferences" do
      @pt.set_preference(:pref_test_pref, 'xyz')
      expect(@pt.preferred_pref_test_pref).to eq 'xyz'
      @pt.clear_preferences
      expect(@pt.preferred_pref_test_pref).to eq 'abc'
    end

    it "clear preferences when record is deleted" do
      @pt.save!
      @pt.preferred_pref_test_pref = 'lmn'
      @pt.save!
      @pt.destroy
      @pt1 = PrefTest.new(col: 'aaaa')
      @pt1.id = @pt.id
      @pt1.save!
      expect(@pt1.get_preference(:pref_test_pref)).to_not eq 'lmn'
      expect(@pt1.get_preference(:pref_test_pref)).to eq 'abc'
    end
  end

  it "builds cache keys" do
    expect(@a.preference_cache_key(:color)).to match %r{a/color/\d+}
  end

  it "can add and remove preferences" do
    A.preference :test_temp, :boolean, default: true
    expect(@a.preferred_test_temp).to be_truthy
    A.remove_preference :test_temp
    expect(@a.has_preference?(:test_temp)).to be_falsy
    expect(@a.respond_to?(:preferred_test_temp)).to be_falsy
  end
end
