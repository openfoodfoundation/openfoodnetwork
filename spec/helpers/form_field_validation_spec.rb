# frozen_string_literal: true

RSpec.describe ActionView::Helpers::FormBuilder do
  let(:view) { ActionView::Base.new(ActionController::Base.view_paths, {}, ActionController::Base.new) }

  let(:model_class) do
    build_model_class do
      attr_accessor :name

      validates :name, length: { maximum: 10 }
    end
  end

  let(:model) { model_class.new }
  let(:form) { described_class.new(:model, model, view, {}) }

  def build_model_class(columns: {}, &)
    Class.new do
      include ActiveModel::Model

      define_singleton_method(:columns_hash) { columns } if columns.any?

      class_eval(&)
    end
  end

  def column(type, limit)
    Struct.new(:type, :limit).new(type, limit)
  end

  shared_examples "a text input that enforces the model maximum length" do |helper|
    it "adds maxlength based on the model validator" do
      expect(form.public_send(helper, :name)).to include 'maxlength="10"'
    end
  end

  %i[
    text_field
    text_area
    email_field
    password_field
    search_field
    url_field
    phone_field
  ].each do |helper|
    describe "##{helper}" do
      it_behaves_like "a text input that enforces the model maximum length", helper
    end
  end

  describe "#text_field" do
    context "with an explicit maxlength option" do
      it "respects the option over the validator" do
        expect(form.text_field(:name, maxlength: 5)).to include 'maxlength="5"'
      end

      it "respects a string-keyed maxlength option" do
        expect(form.text_field(:name, "maxlength" => 7)).to include 'maxlength="7"'
      end
    end

    it "does not mutate the caller's options hash" do
      options = { class: "wide" }

      form.text_field(:name, options)

      expect(options).not_to have_key(:maxlength)
    end

    it "works with a frozen options hash" do
      expect { form.text_field(:name, {}.freeze) }.not_to raise_error
    end

    context "with an exact length validator" do
      let(:model_class) do
        build_model_class do
          attr_accessor :name

          validates :name, length: { is: 8 }
        end
      end

      it "adds maxlength for the exact length" do
        expect(form.text_field(:name)).to include 'maxlength="8"'
      end
    end

    context "with a within range validator" do
      let(:model_class) do
        build_model_class do
          attr_accessor :name

          validates :name, length: { within: 3..12 }
        end
      end

      it "adds maxlength for the range maximum" do
        expect(form.text_field(:name)).to include 'maxlength="12"'
      end
    end

    context "with only a minimum length validator" do
      let(:model_class) do
        build_model_class do
          attr_accessor :name

          validates :name, length: { minimum: 2 }
        end
      end

      it "does not add maxlength" do
        expect(form.text_field(:name)).not_to include "maxlength"
      end
    end

    context "with a conditional length validator" do
      let(:model_class) do
        build_model_class do
          attr_accessor :name

          validates :name, length: { maximum: 10 }, if: :persisted?
        end
      end

      it "does not add maxlength" do
        expect(form.text_field(:name)).not_to include "maxlength"
      end
    end

    context "with a context-scoped length validator" do
      let(:model_class) do
        build_model_class do
          attr_accessor :name

          validates :name, length: { maximum: 10 }, on: :update
        end
      end

      it "does not add maxlength" do
        expect(form.text_field(:name)).not_to include "maxlength"
      end
    end

    context "with an open-ended within range" do
      let(:model_class) do
        build_model_class do
          attr_accessor :name

          validates :name, length: { within: 5.. }
        end
      end

      it "does not raise or add maxlength" do
        expect { form.text_field(:name) }.not_to raise_error
        expect(form.text_field(:name)).not_to include "maxlength"
      end
    end

    context "without a length validator but with a string column limit" do
      let(:model_class) do
        build_model_class(columns: { "name" => column(:string, 255) }) do
          attr_accessor :name
        end
      end

      it "adds maxlength from the database column limit" do
        expect(form.text_field(:name)).to include 'maxlength="255"'
      end
    end

    context "without a length validator and with a text column" do
      let(:model_class) do
        build_model_class(columns: { "name" => column(:text, nil) }) do
          attr_accessor :name
        end
      end

      it "does not add maxlength" do
        expect(form.text_field(:name)).not_to include "maxlength"
      end
    end

    context "with both a validator and a larger column limit" do
      let(:model_class) do
        build_model_class(columns: { "name" => column(:string, 255) }) do
          attr_accessor :name

          validates :name, length: { maximum: 10 }
        end
      end

      it "prefers the explicit validator" do
        expect(form.text_field(:name)).to include 'maxlength="10"'
      end
    end

    context "when the form object is not a model" do
      let(:model) { Struct.new(:name).new("plain object") }

      it "does not add maxlength" do
        expect(form.text_field(:name)).not_to include "maxlength"
      end
    end

    context "when the form has no object" do
      let(:form) { described_class.new(:model, nil, view, {}) }

      it "does not add maxlength" do
        expect(form.text_field(:name)).not_to include "maxlength"
      end
    end

    context "with a decorated model" do
      let(:form) { described_class.new(:model, SimpleDelegator.new(model), view, {}) }

      it "adds maxlength based on the underlying model validator" do
        expect(form.text_field(:name)).to include 'maxlength="10"'
      end
    end
  end

  describe "#text_area" do
    context "with a text column and no validator" do
      let(:model_class) do
        build_model_class(columns: { "description" => column(:text, nil) }) do
          attr_accessor :description
        end
      end

      it "does not add maxlength from the database" do
        expect(form.text_area(:description)).not_to include "maxlength"
      end
    end
  end
end
