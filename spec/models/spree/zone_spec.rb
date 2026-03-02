# frozen_string_literal: true

RSpec.describe Spree::Zone do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:zone_members) }
  end

  describe "#match" do
    let(:country_zone) { create(:zone, name: 'CountryZone') }
    let(:country) do
      country = create(:country)
      # Create at least one state for this country
      state = create(:state, country:)
      country
    end

    before { country_zone.members.create(zoneable: country) }

    context "when there is only one qualifying zone" do
      let(:address) { create(:address, country:, state: country.states.first) }

      it "should return the qualifying zone" do
        expect(Spree::Zone.match(address)).to eq country_zone
      end
    end

    context "when there are two qualified zones with same member type" do
      let(:address) { create(:address, country:, state: country.states.first) }
      let(:second_zone) { create(:zone, name: 'SecondZone') }

      before { second_zone.members.create(zoneable: country) }

      context "when both zones have the same number of members" do
        it "should return the zone that was created first" do
          expect(Spree::Zone.match(address)).to eq country_zone
        end
      end

      context "when one of the zones has fewer members" do
        let(:country2) { create(:country) }

        before { country_zone.members.create(zoneable: country2) }

        it "should return the zone with fewer members" do
          expect(Spree::Zone.match(address)).to eq second_zone
        end
      end
    end

    context "when there are two qualified zones with different member types" do
      let(:state_zone) { create(:zone, name: 'StateZone') }
      let(:address) { create(:address, country:, state: country.states.first) }

      before { state_zone.members.create(zoneable: country.states.first) }

      it "should return the zone with the more specific member type" do
        expect(Spree::Zone.match(address)).to eq state_zone
      end
    end

    context "when there are no qualifying zones" do
      it "should return nil" do
        expect(Spree::Zone.match(Spree::Address.new)).to be_nil
      end
    end
  end

  describe "#countries" do
    let(:state) { create(:state) }
    let(:country) { state.country }

    context "when zone consists of countries" do
      let(:country_zone) { create(:zone, name: 'CountryZone', member: country) }

      it 'should return a list of countries' do
        expect(country_zone.countries).to eq [country]
      end
    end

    context "when zone consists of states" do
      let(:state_zone) { create(:zone, name: 'StateZone', member: state) }

      it 'should return a list of countries' do
        expect(state_zone.countries).to eq [country]
      end
    end
  end

  describe "#contains_address?" do
    let(:state) { create(:state) }
    let(:country) { state.country }
    let(:address) { create(:address, country:, state:) }

    context "when zone is country type" do
      let(:country_zone) { create(:zone, name: 'CountryZone') }
      before { country_zone.members.create(zoneable: country) }

      it "should be true" do
        expect(country_zone.contains_address?(address)).to be_truthy
      end
    end

    context "when zone is state type" do
      let(:state_zone) { create(:zone, name: 'StateZone') }
      before { state_zone.members.create(zoneable: state) }

      it "should be true" do
        expect(state_zone.contains_address?(address)).to be_truthy
      end
    end
  end

  describe ".default_tax" do
    context "when there is a default tax zone specified" do
      let!(:default_zone) { create(:zone, name: 'whatever', default_tax: true) }

      it "should be the correct zone" do
        create(:zone, name: 'foo', default_tax: false)
        expect(Spree::Zone.default_tax).to eq default_zone
      end
    end

    context "when there is no default tax zone specified" do
      it "should be nil" do
        expect(Spree::Zone.default_tax).to be_nil
      end
    end
  end

  describe "#contains?" do
    let(:country_member1) { Spree::ZoneMember.create(zoneable: create(:country)) }
    let(:country_member2) { Spree::ZoneMember.create(zoneable: create(:country)) }
    let(:country_member3) { Spree::ZoneMember.create(zoneable: create(:country)) }
    let(:source) { create(:zone, name: 'source') }
    let(:target) { create(:zone, name: 'target') }

    context "when both zones are the same zone" do
      before do
        source.zone_members = [country_member1]
      end

      it "should be true" do
        target = source

        expect(source.contains?(target)).to be_truthy
      end
    end

    context "when both zones are of the same type" do
      before do
        source.zone_members = [country_member1, country_member2]
      end

      context "when all members are included in the zone we check against" do
        before do
          target.zone_members = [country_member1, country_member2]
        end

        it "should be true" do
          expect(source.contains?(target)).to be_truthy
        end
      end

      context "when some members are included in the zone we check against" do
        before do
          target.zone_members = [
            country_member1, country_member2, Spree::ZoneMember.create(zoneable: create(:country))
          ]
        end

        it "should be false" do
          expect(source.contains?(target)).to be_falsy
        end
      end

      context "when none of the members are included in the zone we check against" do
        before do
          target.zone_members = [
            Spree::ZoneMember.create(zoneable: create(:country)),
            Spree::ZoneMember.create(zoneable: create(:country))
          ]
        end

        it "should be false" do
          expect(source.contains?(target)).to be_falsy
        end
      end
    end

    context "when checking country against state" do
      before do
        source.zone_members = [Spree::ZoneMember.create(zoneable: create(:state))]
        target.zone_members = [country_member1]
      end

      it "should be false" do
        expect(source.contains?(target)).to be_falsy
      end
    end

    context "when checking state against country" do
      before { source.zone_members = [country_member1] }

      context "when all states contained in one of the countries we check against" do
        before do
          state1 = create(:state, country: country_member1.zoneable)
          target.zone_members = [Spree::ZoneMember.create(zoneable: state1)]
        end

        it "should be true" do
          expect(source.contains?(target)).to be_truthy
        end
      end

      context "when some states contained in one of the countries we check against" do
        before do
          state1 = create(:state, country: country_member1.zoneable)
          state2 = create(:state, country: country_member2.zoneable)
          target.zone_members = [
            Spree::ZoneMember.create(zoneable: state1),
            Spree::ZoneMember.create(zoneable: state2)
          ]
        end

        it "should be false" do
          expect(source.contains?(target)).to be_falsy
        end
      end

      context "when none of the states contained in any of the countries we check against" do
        before do
          target.zone_members = [
            Spree::ZoneMember.create(zoneable: create(:state, country: country_member2.zoneable)),
            Spree::ZoneMember.create(zoneable: create(:state, country: country_member2.zoneable))
          ]
        end

        it "should be false" do
          expect(source.contains?(target)).to be_falsy
        end
      end
    end
  end

  describe "#save" do
    context "when default_tax is true" do
      it "should clear previous default tax zone" do
        zone1 = create(:zone, name: 'foo', default_tax: true)
        zone = create(:zone, name: 'bar', default_tax: true)
        expect(zone1.reload.default_tax).to be_falsy
      end
    end

    context "when a zone member country is added to an existing zone consisting of state members" do
      it "should remove existing state members" do
        state = create(:state)
        zone = create(:zone, name: 'foo', member: state)

        country = create(:country)
        country_member = zone.members.create(zoneable: country)
        zone.save

        expect(zone.reload.members).to eq [country_member]
      end
    end
  end

  describe "#kind" do
    context "when the zone consists of country zone members" do
      let!(:zone) { create(:zone, name: 'country', member: create(:country)) }

      it "should return the kind of zone member" do
        expect(zone.kind).to eq "country"
      end
    end

    context "when the zone consists of state zone members" do
      let!(:zone) { create(:zone, name: 'country', member: create(:state)) }

      it "should return the kind of zone member" do
        expect(zone.kind).to eq "state"
      end
    end
  end
end
