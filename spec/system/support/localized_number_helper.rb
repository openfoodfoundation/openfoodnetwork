# frozen_string_literal: true

shared_examples "a model using the LocalizedNumber module" do |attributes|
  before do
    allow(Spree::Config).to receive(:enable_localized_number?).and_return true
  end

  attributes.each do |attribute|
    setter = "#{attribute}="

    it "uses the LocalizedNumber.parse method when setting #{attribute}" do
      allow(Spree::LocalizedNumber).to receive(:parse).and_return(nil)
      expect(Spree::LocalizedNumber).to receive(:parse).with('1.599,99')
      subject.send(setter, '1.599,99')
    end

    it "creates an error if the input to #{attribute} is invalid" do
      subject.send(setter, '1.59,99')
      subject.valid?
      expect(subject.errors[attribute]).to include(I18n.t('spree.localized_number.invalid_format'))
    end
  end
end
