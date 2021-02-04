require 'spec_helper'

describe 'config/initializers/feature_toggles.rb' do
  # Executes the initializer's code block by reading the Ruby file. Note that `Kernel#require` would
  # prevent this from happening twice.
  subject(:execute_initializer) do
    load Rails.root.join('config/initializers/feature_toggles.rb')
  end

  let(:user) { build(:user) }

  around do |example|
    original = ENV['BETA_TESTERS']
    example.run
    ENV['BETA_TESTERS'] = original
  end

  context 'when beta_testers is ["all"]' do
    before { ENV['BETA_TESTERS'] = 'all' }

    it 'returns true' do
      execute_initializer

      enabled = OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, user)
      expect(enabled).to eq(true)
    end
  end

  context 'when beta_testers is a list of emails' do
    let(:other_user) { build(:user) }

    context 'and the user is in the list' do
      before { ENV['BETA_TESTERS'] = "#{user.email}, #{other_user.email}" }

      it 'enables the feature' do
        execute_initializer

        enabled = OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, user)
        expect(enabled).to eq(true)
      end
    end

    context 'and the user is not in the list' do
      before { ENV['BETA_TESTERS'] = "#{other_user.email}" }

      it 'disables the feature' do
        execute_initializer

        enabled = OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, user)
        expect(enabled).to eq(false)
      end
    end

    context 'and the list is empty' do
      before { ENV['BETA_TESTERS'] = '' }

      it 'disables the feature' do
        execute_initializer

        enabled = OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, user)
        expect(enabled).to eq(false)
      end
    end
  end
end
