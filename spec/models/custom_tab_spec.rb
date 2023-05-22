# frozen_string_literal: true

require 'spec_helper'

describe CustomTab do
  let(:enterprise) { build(:enterprise) }

  describe 'associations' do
    it { is_expected.to belong_to(:enterprise).required }
  end
end
