# frozen_string_literal: true

require 'spec_helper'

describe CustomTab do
  describe 'associations' do
    it { is_expected.to belong_to(:enterprise).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
  end
end
