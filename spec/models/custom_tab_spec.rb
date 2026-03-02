# frozen_string_literal: true

RSpec.describe CustomTab do
  describe 'associations' do
    it { is_expected.to belong_to(:enterprise).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }

    it { is_expected.to validate_length_of(:title).is_at_most(20) }
  end

  describe "serialisation" do
    it "sanitises HTML in content" do
      subject.content = "Hello <script>alert</script> dearest <b>monster</b>."
      expect(subject.content).to eq "Hello alert dearest <b>monster</b>."
    end
  end
end
