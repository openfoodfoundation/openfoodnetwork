# frozen_string_literal: true

require 'spec_helper'
require 'haml_up'

describe HamlUp, skip: !Gem::Dependency.new("", "~> 5.2").match?("", Haml::VERSION) do
  describe "#rewrite_template" do
    it "preserves a simple template" do
      original = "%p This is a paragraph"
      template = call(original)
      expect(template).to eq original
    end

    it "rewrites non-standard attribute hashes" do
      original = "%p{ng: {click: 'action', show: 'condition'}} label"
      template = call(original)
      expect(template).to eq "%p{ \"ng-click\": 'action', \"ng-show\": 'condition' } label"
    end

    it "preserves standard attribute hashes" do
      original = "%p{data: {click: 'action', show: 'condition'}} label"
      template = call(original)
      expect(template).to eq original
    end

    it "preserves standard attribute hashes while rewriting others" do
      original = "%p{data: {click: 'standard'}, ng: {click: 'not'}} label"
      template = call(original)
      expect(template).to eq "%p{ data: {click: 'standard'}, \"ng-click\": 'not' } label"
    end

    it "rewrites multi-line attributes" do
      original = <<~HAML
        %li{ ng: { class: "{active: selector.active}" } }
          %a{ tooltip: "{{selector.object.value}}", "tooltip-placement": "bottom",
            ng: { transclude: true, class: "{active: selector.active, 'has-tip': selector.object.value}" } }
      HAML
      expected = <<~HAML
        %li{ "ng-class": "{active: selector.active}" }
          %a{ tooltip: "{{selector.object.value}}", "tooltip-placement": "bottom", "ng-transclude": true, "ng-class": "{active: selector.active, 'has-tip': selector.object.value}" }
      HAML
      template = call(original)
      expect(template).to eq expected
    end

    def call(original)
      original.dup.tap { |t| subject.rewrite_template(t) }
    end
  end
end
