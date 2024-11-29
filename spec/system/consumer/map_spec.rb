# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'Map' do
  context 'map cannot load' do
    it 'shows alert' do
      message = accept_alert { visit '/map' }
      expect(message).to eq(
        "Unable to load map. Please check your browser " \
        "settings and allow 3rd party cookies for this website."
      )
    end
  end
end
