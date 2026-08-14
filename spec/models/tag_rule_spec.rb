# frozen_string_literal: true

RSpec.describe TagRule do
  describe "validations" do
    it "requires a enterprise" do
      expect(subject).to belong_to(:enterprise)
    end
  end

  describe 'TYPES' do
    it "lists exactly the concrete TagRule subclasses" do
      expect(TagRule::TYPES).to match_array(
        Rails.root.glob("app/models/tag_rule/*.rb").map do |path|
          "TagRule::#{File.basename(path, '.rb').camelize}"
        end
      )
    end

    it "only contains classes that inherit from TagRule" do
      TagRule::TYPES.each do |type|
        expect(type.constantize.ancestors).to include(TagRule)
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
