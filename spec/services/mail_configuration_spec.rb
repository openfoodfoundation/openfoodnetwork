# frozen_string_literal: true

require 'spec_helper'

describe MailConfiguration do
  describe 'apply!' do
    before do
      allow(Spree::Core::MailSettings).to receive(:init) { true }
    end

    it 'sets config entries in the Spree Config' do
      allow(Spree::Config).to receive(:[]=)

      described_class.apply!
      expect(Spree::Config).to have_received(:[]=).with(:mail_host, "example.com")
      expect(Spree::Config).to have_received(:[]=).with(:mail_domain, "example.com")
      expect(Spree::Config).to have_received(:[]=).with(:mail_port, "25")
      expect(Spree::Config).to have_received(:[]=).with(:mail_auth_type, "login")
      expect(Spree::Config).to have_received(:[]=).with(:smtp_username, "ofn")
      expect(Spree::Config).to have_received(:[]=).with(:smtp_password, "f00d")
      expect(Spree::Config).to have_received(:[]=).with(:secure_connection_type, "None")
      expect(Spree::Config).to have_received(:[]=).with(:mails_from, "no-reply@example.com")
      expect(Spree::Config).to have_received(:[]=).with(:mail_bcc, "")
    end

    it 'initializes the mail settings' do
      described_class.apply!
      expect(Spree::Core::MailSettings).to have_received(:init)
    end
  end
end
