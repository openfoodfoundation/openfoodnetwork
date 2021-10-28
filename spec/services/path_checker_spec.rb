# frozen_string_literal: true

require 'spec_helper'

describe PathChecker do
  describe "#active_path?" do
    let(:view_context) { double("view context") }

    before do
      allow(view_context).to receive_message_chain("main_app.root_path") { "/" }
    end

    context "when fullpath starts with match_path and except_paths is blank" do
      it "returns true" do
        checker = described_class.new("/admin/products", view_context)
        expect(checker.active_path?("/products")).to be true
        expect(checker.active_path?("/products", nil)).to be true
        expect(checker.active_path?("/products", [])).to be true

        checker = described_class.new("/admin/products/5/variants", view_context)
        expect(checker.active_path?("/products")).to be true
        expect(checker.active_path?("/products", nil)).to be true
        expect(checker.active_path?("/products", [])).to be true
      end
    end

    context "when fullpath doesn't start with match_path" do
      it "returns false" do
        checker = described_class.new("/admin/products", view_context)
        expect(checker.active_path?("/orders")).to be false
      end
    end

    context "when fullpath starts with match_path and doesn't start with any of except_paths" do
      it "returns true" do
        checker = described_class.new("/admin/products", view_context)
        expect(checker.active_path?("/products", ["/orders/bulk_management"])).to be true
      end
    end

    context "when fullpath starts with match_path also with one of except_paths" do
      it "returns false" do
        checker = described_class.new("/admin/orders/bulk_management", view_context)
        expect(checker.active_path?("/orders", ["/orders/bulk_management"])).to be false
      end
    end
  end
end
