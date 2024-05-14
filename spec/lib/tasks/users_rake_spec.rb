# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'users.rake' do
  before do
    Rake.application.rake_require 'tasks/users'
    Rake::Task.define_task(:environment)
    Rake::Task['ofn:remove_enterprise_limit'].reenable
  end

  describe ':remove_enterprise_limit' do
    context 'when the user exists' do
      let(:user) { create(:user) }

      it 'sets the enterprise_limit to the maximum integer' do
        Rake.application.invoke_task "ofn:remove_enterprise_limit[#{user.id}]"

        expect(user.reload.enterprise_limit).to eq(2_147_483_647)
      end
    end

    context 'when the user does not exist' do
      it 'raises' do
        expect {
          Rake.application.invoke_task "ofn:remove_enterprise_limit[123]"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
