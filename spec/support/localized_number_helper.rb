shared_examples "a model using the LocalizedNumber module" do |attributes|
  before do
    Spree::Config[:enable_localized_number?] = true
  end

  after do
    Spree::Config[:enable_localized_number?] = false
  end

  attributes.each do |attribute|
    setter = "#{attribute}="

    it "uses the LocalizedNumber.parse method when setting #{attribute}" do
      expect(Spree::LocalizedNumber).to receive(:parse).with('1.599,99') { 1234.56 }
      subject.send(setter, '1.599,99')
      expect(subject.send(attribute)).to eq 1234.56
    end

    it "creates an error if the input to #{attribute} is invalid" do
      subject.send(setter, '1.59,99')
      subject.valid?
      expect(subject.errors[attribute]).to include(I18n.t('spree.localized_number.invalid_format'))
    end
  end
end
