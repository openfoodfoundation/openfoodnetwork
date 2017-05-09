require 'spec_helper'

describe Spree::UserMailer do
  let(:user) { build(:user) }

  after do
    ActionMailer::Base.deliveries.clear
  end

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  it "sends an email when given a user" do
    Spree::UserMailer.signup_confirmation(user).deliver
    ActionMailer::Base.deliveries.count.should == 1
  end

  # adapted from https://github.com/spree/spree_auth_devise/blob/70737af/spec/mailers/user_mailer_spec.rb
  describe '#reset_password_instructions' do
    describe 'message contents' do
      before do
        @message = described_class.reset_password_instructions(user)
      end

      context 'subject includes' do
        it 'translated devise instructions' do
          expect(@message.subject).to include "Reset password instructions"
        end

        it 'Spree site name' do
          expect(@message.subject).to include Spree::Config[:site_name]
        end
      end

      context 'body includes' do
        it 'password reset url' do
          expect(@message.body.raw_source).to include root_url + "user/spree_user/password/edit"
        end
      end
    end

    describe 'legacy support for User object' do
      it 'sends an email' do
        expect do
          Spree::UserMailer.reset_password_instructions(user).deliver
        end.to change(ActionMailer::Base.deliveries, :size).by(1)
      end
    end
  end
end
