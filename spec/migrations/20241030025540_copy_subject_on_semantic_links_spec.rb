# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20241030025540_copy_subject_on_semantic_links'

RSpec.describe CopySubjectOnSemanticLinks do
  describe "#up" do
    let(:original_variant) { create(:variant) }
    let(:dummy_variant) { create(:variant) }

    it "copies the original data" do
      link = SemanticLink.create!(
        subject: dummy_variant, # This would be NULL when migration runs.
        semantic_id: "some-url",
      )
      SemanticLink.update_all("variant_id = #{original_variant.id}")

      expect { subject.up }.to change {
        link.reload.subject
      }.from(dummy_variant).to(original_variant)
    end
  end
end
