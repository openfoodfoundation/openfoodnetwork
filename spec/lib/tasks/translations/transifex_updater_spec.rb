# frozen_string_literal: true

require 'spec_helper'
require 'tasks/translations/transifex_updater'

describe TransifexUpdater do
  describe "#deep_diff_merge" do
    let(:subject) { TransifexUpdater.new }
    let(:current_translations) {
      { "es" =>
        { "fruits" =>
           { "apples" => "Manzanas",
             "oranges" => "Naranjas" },
          "vegetables" =>
           { "tomatos" => "Tomates" },
          "baked_goods" =>
           { "bread" => "Pan" } } }
    }
    let(:new_translations) {
      { "es" =>
        { "fruits" =>
          { "apples" => "Manzanitas",
            "pears" => "Peras",
            "bags" =>
             { "grapes" => "Uvas" } },
          "vegetables" =>
          { "tomatos" => "Tomates Grandes" } } }
    }
    let(:expected_output) {
      { "es" =>
        { "fruits" =>
           { "apples" => "Manzanitas",
             "oranges" => "Naranjas" },
          "vegetables" =>
             { "tomatos" => "Tomates Grandes" },
          "baked_goods" =>
             { "bread" => "Pan" } } }
    }

    it "merges compatible upstream translations" do
      merged_data = subject.__send__(:deep_diff_merge, current_translations, new_translations)

      expect(merged_data).to eq expected_output
    end
  end
end
