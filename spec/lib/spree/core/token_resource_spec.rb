# frozen_string_literal: true

require 'spec_helper'

# Its pretty difficult to test this module in isolation b/c it needs to work in conjunction
#   with an actual class that extends ActiveRecord::Base and has a corresponding table in the DB.
#   So we'll just test it using Order instead since it included the module.
describe Spree::Core::TokenResource do
  let(:order) { Spree::Order.new }
  let(:permission) { double(Spree::TokenizedPermission) }

  it 'should add has_one :tokenized_permission relationship' do
    assert Spree::Order.
      reflect_on_all_associations(:has_one).map(&:name).include?(:tokenized_permission)
  end

  context '#token' do
    it 'should return the token of the associated permission' do
      allow(order).to receive_messages tokenized_permission: permission
      allow(permission).to receive_messages token: 'foo'
      expect(order.token).to eq 'foo'
    end

    it 'should return nil if there is no associated permission' do
      expect(order.token).to be_nil
    end
  end

  context '#create_token' do
    it 'should create a randomized 16 character token' do
      token = order.create_token
      expect(token.size).to eq 16
    end
  end
end
