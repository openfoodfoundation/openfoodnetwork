# frozen_string_literal: true

RSpec.describe TagRule do
  describe "validations" do
    it "requires a enterprise" do
      expect(subject).to belong_to(:enterprise)
    end
  end

  describe ".matching_variant_tag_rules_by_enterprises" do
    let(:enterprise) { create(:enterprise) }
    let!(:rule1) {
      create(:filter_variants_tag_rule, enterprise:, preferred_variant_tags: "filtered" )
    }
    let!(:rule2) {
      create(:filter_variants_tag_rule, enterprise:, preferred_variant_tags: "filtered" )
    }
    let!(:rule3) {
      create(:filter_variants_tag_rule, enterprise: create(:enterprise),
                                        preferred_variant_tags: "filtered" )
    }
    let!(:rule4) {
      create(:filter_variants_tag_rule, enterprise:, preferred_variant_tags: "other-tag" )
    }
    let!(:rule5) {
      create(:filter_order_cycles_tag_rule, enterprise:, preferred_exchange_tags: "filtered" )
    }

    it "returns a list of rule partially matching the tag" do
      rules = described_class.matching_variant_tag_rules_by_enterprises(enterprise.id, "filte")

      expect(rules).to include rule1, rule2
      expect(rules).not_to include rule3, rule4, rule5
    end

    context "when no matching rules" do
      it "returns an empty array" do
        rules = described_class.matching_variant_tag_rules_by_enterprises(enterprise.id, "no-tag")
        expect(rules).to eq([])
      end
    end
  end

  describe '#tags' do
    subject(:rule) { Class.new(TagRule).new }

    it "raises not implemented error" do
      expect{ rule.tags }.to raise_error(NotImplementedError, 'please use concrete TagRule')
    end
  end
end
