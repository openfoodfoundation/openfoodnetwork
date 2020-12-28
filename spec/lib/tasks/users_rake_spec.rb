# frozen_string_literal: true

require 'spec_helper'
require 'rake'

describe 'users.rake' do
  before(:all) do
    Rake.application.rake_require 'tasks/users'
    Rake::Task.define_task(:environment)
  end

  describe ':remove_enterprise_limit' do
    context 'when the user exists' do
      it 'sets the enterprise_limit to the maximum integer' do
        max_integer = 2_147_483_647
        user = create(:user)

        Rake.application.invoke_task "ofn:remove_enterprise_limit[#{user.id}]"

        expect(user.reload.enterprise_limit).to eq(max_integer)
      end
    end

    context 'when the user does not exist' do
      it 'raises' do
        expect {
          RemoveEnterpriseLimit.new(-1).call
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
