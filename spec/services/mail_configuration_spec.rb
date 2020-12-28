# frozen_string_literal: true

require 'spec_helper'

describe MailConfiguration do
  describe 'entries=' do
    let(:mail_settings) { instance_double(Spree::Core::MailSettings) }
    let(:entries) do
      { smtp_username: "smtp_username", mail_auth_type: "login" }
    end

    before do
      allow(Spree::Core::MailSettings).to receive(:init) { mail_settings }
    end

    # keeps spree_config unchanged
    around do |example|
      original_smtp_username = Spree::Config[:smtp_username]
      original_mail_auth_type = Spree::Config[:mail_auth_type]
      example.run
      Spree::Config[:smtp_username] = original_smtp_username
      Spree::Config[:mail_auth_type] = original_mail_auth_type
    end

    it 'sets config entries in the Spree Config' do
      described_class.entries = entries
      expect(Spree::Config[:smtp_username]).to eq("smtp_username")
      expect(Spree::Config[:mail_auth_type]).to eq("login")
    end

    it 'initializes the mail settings' do
      described_class.entries = entries
      expect(Spree::Core::MailSettings).to have_received(:init)
    end
  end
end
