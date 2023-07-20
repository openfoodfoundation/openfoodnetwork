# frozen_string_literal: true

require 'spec_helper'

describe VariantOverride do
  let(:variant) { create(:variant) }
  let(:hub)     { create(:distributor_enterprise) }

  describe "scopes" do
    let(:hub1) { create(:distributor_enterprise) }
    let(:hub2) { create(:distributor_enterprise) }
    let!(:vo1) {
      create(:variant_override, hub: hub1, variant: variant, import_date: Time.zone.now.yesterday)
    }
    let!(:vo2) {
      create(:variant_override, hub: hub2, variant: variant, import_date: Time.zone.now)
    }
    let!(:vo3) {
      create(:variant_override, hub: hub1, variant: variant, permission_revoked_at: Time.zone.now)
    }

    it "ignores variant_overrides with revoked_permissions by default" do
      expect(VariantOverride.all).to_not include vo3
      expect(VariantOverride.unscoped).to include vo3
    end

    it "finds variant overrides for a set of hubs" do
      expect(VariantOverride.for_hubs([hub1, hub2])).to match_array [vo1, vo2]
    end

    it "fetches import dates for hubs in descending order" do
      import_dates = VariantOverride.distinct_import_dates.pluck :import_date

      expect(import_dates[0].to_i).to eq(vo2.import_date.to_i)
      expect(import_dates[1].to_i).to eq(vo1.import_date.to_i)
    end

    describe "fetching variant overrides indexed by variant" do
      it "gets indexed variant overrides for one hub" do
        expect(VariantOverride.indexed(hub1)).to eq( variant => vo1 )
        expect(VariantOverride.indexed(hub2)).to eq( variant => vo2 )
      end

      it "does not include overrides for soft-deleted variants" do
        variant.delete
        expect(VariantOverride.indexed(hub1)).to eq( nil => vo1 )
      end
    end
  end

  describe "validation" do
    describe "ensuring that on_demand and count_on_hand are compatible" do
      let(:variant_override) do
        build_stubbed(
          :variant_override,
          hub: build_stubbed(:distributor_enterprise),
          variant: build_stubbed(:variant),
          on_demand: on_demand,
          count_on_hand: count_on_hand
        )
      end

      context "when using producer stock settings" do
        let(:on_demand) { nil }

        context "when count_on_hand is blank" do
          let(:count_on_hand) { nil }

          it "is valid" do
            expect(variant_override).to be_valid
          end
        end

        context "when count_on_hand is set" do
          let(:count_on_hand) { 1 }

          it "is invalid" do
            expect(variant_override).not_to be_valid
            error_message = I18n.t("using_producer_stock_settings_but_count_on_hand_set",
                                   scope: [i18n_scope_for_error, "count_on_hand"])
            expect(variant_override.errors[:count_on_hand]).to eq([error_message])
          end
        end
      end

      context "when on demand" do
        let(:on_demand) { true }

        context "when count_on_hand is blank" do
          let(:count_on_hand) { nil }

          it "is valid" do
            expect(variant_override).to be_valid
          end
        end

        context "when count_on_hand is set" do
          let(:count_on_hand) { 1 }

          it "is invalid" do
            expect(variant_override).not_to be_valid
            error_message = I18n.t("on_demand_but_count_on_hand_set",
                                   scope: [i18n_scope_for_error, "count_on_hand"])
            expect(variant_override.errors[:count_on_hand]).to eq([error_message])
          end
        end
      end

      context "when limited stock" do
        let(:on_demand) { false }

        context "when count_on_hand is blank" do
          let(:count_on_hand) { nil }

          it "is invalid" do
            expect(variant_override).not_to be_valid
            error_message = I18n.t("limited_stock_but_no_count_on_hand",
                                   scope: [i18n_scope_for_error, "count_on_hand"])
            expect(variant_override.errors[:count_on_hand]).to eq([error_message])
          end
        end

        context "when count_on_hand is set" do
          let(:count_on_hand) { 1 }

          it "is valid" do
            expect(variant_override).to be_valid
          end
        end
      end
    end
  end

  describe "delegated price" do
    let!(:variant_with_price) { create(:variant, price: 123.45) }
    let(:price_object) { variant_with_price.default_price }

    context "when variant is soft-deleted" do
      before do
        variant_with_price.destroy
      end

      it "soft-deletes the price" do
        expect(price_object.reload.deleted_at).to_not be_nil
      end

      it "can access the soft-deleted price" do
        expect(variant_with_price.reload.default_price).to eq price_object
        expect(variant_with_price.price).to eq 123.45
      end
    end
  end

  describe "with price" do
    let(:variant_override) do
      build_stubbed(
        :variant_override,
        variant: build_stubbed(:variant),
        hub: build_stubbed(:distributor_enterprise),
        price: 12.34
      )
    end

    it "returns the numeric price" do
      expect(variant_override.price).to eq(12.34)
    end
  end

  describe "with nil count on hand" do
    let(:variant_override) do
      build_stubbed(
        :variant_override,
        variant: build_stubbed(:variant),
        hub: build_stubbed(:distributor_enterprise),
        count_on_hand: nil,
        on_demand: true
      )
    end

    describe "stock_overridden?" do
      it "returns false" do
        expect(variant_override.stock_overridden?).to be false
      end
    end

    describe "move_stock!" do
      it "silently logs an error" do
        expect(Bugsnag).to receive(:notify)
        variant_override.move_stock!(5)
      end
    end
  end

  describe "with count on hand" do
    let(:variant_override) do
      build_stubbed(
        :variant_override,
        variant: build_stubbed(:variant),
        hub: build_stubbed(:distributor_enterprise),
        count_on_hand: 12
      )
    end

    it "returns the numeric count on hand" do
      expect(variant_override.count_on_hand).to eq(12)
    end

    describe "stock_overridden?" do
      it "returns true" do
        expect(variant_override.stock_overridden?).to be true
      end
    end

    describe "move_stock!" do
      let(:variant_override) do
        create(
          :variant_override,
          variant: variant,
          hub: hub,
          count_on_hand: 12
        )
      end

      it "does nothing for quantity zero" do
        variant_override.move_stock!(0)
        expect(variant_override.reload.count_on_hand).to eq(12)
      end

      it "increments count_on_hand when quantity is negative" do
        variant_override.move_stock!(2)
        expect(variant_override.reload.count_on_hand).to eq(14)
      end

      it "decrements count_on_hand when quantity is negative" do
        variant_override.move_stock!(-2)
        expect(variant_override.reload.count_on_hand).to eq(10)
      end
    end
  end

  describe "checking default stock value is present" do
    it "returns true when a default stock level has been set" do
      vo = build_stubbed(
        :variant_override,
        variant: build_stubbed(:variant),
        hub: build_stubbed(:distributor_enterprise),
        count_on_hand: 12,
        default_stock: 20
      )
      expect(vo.default_stock?).to be true
    end

    it "returns false when the override has no default stock level" do
      vo = build_stubbed(
        :variant_override,
        variant: build_stubbed(:variant),
        hub: build_stubbed(:distributor_enterprise),
        count_on_hand: 12,
        default_stock: nil
      )
      expect(vo.default_stock?).to be false
    end
  end

  describe "resetting stock levels" do
    describe "forcing the on hand level to the value in the default_stock field" do
      it "succeeds for variant override that forces limited stock" do
        vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12,
                                       default_stock: 20, resettable: true)
        vo.reset_stock!

        vo.reload
        expect(vo.on_demand).to eq(false)
        expect(vo.count_on_hand).to eq(20)
      end

      it "succeeds for variant override that forces unlimited stock" do
        vo = create(:variant_override, :on_demand, variant: variant, hub: hub, default_stock: 20,
                                                   resettable: true)
        vo.reset_stock!

        vo.reload
        expect(vo.on_demand).to eq(false)
        expect(vo.count_on_hand).to eq(20)
      end

      it "succeeds for variant override that uses producer stock settings" do
        vo = create(:variant_override, :use_producer_stock_settings, variant: variant, hub: hub,
                                                                     default_stock: 20,
                                                                     resettable: true)
        vo.reset_stock!

        vo.reload
        expect(vo.on_demand).to eq(false)
        expect(vo.count_on_hand).to eq(20)
      end
    end

    it "silently logs an error if the variant override doesn't have a default stock level" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12,
                                     default_stock: nil, resettable: true)
      expect(Bugsnag).to receive(:notify)
      vo.reset_stock!
      expect(vo.reload.count_on_hand).to eq(12)
    end

    it "doesn't reset the level if the behaviour is disabled" do
      vo = create(:variant_override, variant: variant, hub: hub, count_on_hand: 12,
                                     default_stock: 10, resettable: false)
      vo.reset_stock!
      expect(vo.reload.count_on_hand).to eq(12)
    end
  end

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:price]
  end

  def i18n_scope_for_error
    "activerecord.errors.models.variant_override"
  end
end
