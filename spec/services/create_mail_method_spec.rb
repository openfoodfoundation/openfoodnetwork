require 'spec_helper'

describe CreateMailMethod do
  describe '#call' do
    let(:mail_method) { Spree::MailMethod.create(environment: 'test') }
    let(:mail_settings) { instance_double(Spree::Core::MailSettings) }
    let(:attributes) do
      { preferred_smtp_username: "smtp_username", environment: "test" }
    end

    before do
      allow(Spree::MailMethod)
        .to receive(:create).with(environment: 'test').and_return(mail_method)
      allow(Spree::Core::MailSettings).to receive(:init) { mail_settings }
    end

    context 'unit' do
      before do
        allow(mail_method).to receive(:update_attributes).with(attributes)
      end

      it 'creates a new MailMethod' do
        described_class.new(attributes).call

        expect(Spree::MailMethod)
          .to have_received(:create).with(environment: 'test') { mail_method }
      end

      it 'updates the MailMethod' do
        described_class.new(attributes).call

        expect(mail_method)
          .to have_received(:update_attributes).with(attributes) { mail_method }
      end

      it 'initializes the mail settings' do
        described_class.new(attributes).call
        expect(Spree::Core::MailSettings).to have_received(:init)
      end
    end

    context 'integration' do
      it 'updates the mail method attributes' do
        described_class.new(attributes).call
        expect(mail_method.preferred_smtp_username).to eq('smtp_username')
      end
    end
  end
end
