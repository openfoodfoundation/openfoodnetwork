# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SemanticLink, type: :model do
  it { is_expected.to belong_to :variant }
  it { is_expected.to validate_presence_of(:semantic_id) }
  it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
end
