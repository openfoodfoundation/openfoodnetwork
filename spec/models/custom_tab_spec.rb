# frozen_string_literal: true

require 'spec_helper'

describe CustomTab do
  describe 'associations' do
    it { is_expected.to belong_to(:enterprise).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }

    it { is_expected.to validate_length_of(:title).is_at_most(20) }
  end
end
