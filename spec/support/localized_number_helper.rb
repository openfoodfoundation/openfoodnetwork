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
      expect(subject.errors[attribute]).to include('has an invalid format. Please enter a number.')
    end
  end
end

shared_examples "a Spree Calculator model using the LocalizedNumber module" do |attributes|
  before do
    allow(Spree::Config).to receive(:enable_localized_number?).and_return true
  end

  attributes.each do |attribute|
    setter = "#{attribute}="

    it do
      should_not validate_numericality_of(attribute).
        with_message(I18n.t('activerecord.errors.messages.calculator_preferred_value_error'))
    end

    it "does not modify the attribute value when it is invalid" do
      subject.send(setter, 'invalid')
      subject.valid?
      expect(subject.send(attribute)).to eq 'invalid'
    end
  end
end
