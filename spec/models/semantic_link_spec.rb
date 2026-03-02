# frozen_string_literal: true

RSpec.describe SemanticLink do
  it { is_expected.to belong_to :subject }
  it { is_expected.to validate_presence_of(:semantic_id) }
end
