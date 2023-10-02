# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Database" do
  let(:models_todo) {
    ["Spree::CreditCard", "Spree::Adjustment",
     "StripeAccount", "ColumnPreference",
     "Spree::LineItem", "Spree::ShippingMethod",
     "Spree::ShippingRate"].freeze
  }
  it "should have foreign keys for models with a belongs_to relationship" do
    Rails.application.eager_load!
    model_classes = filter_model_classes

    migrations = generate_migrations(model_classes)

    expect(migrations.length).to eq(0)
  end

  def filter_model_classes
    Dir.glob(Rails.root.join('app/models/**/*.rb').to_s)
      .map { |file| File.basename(file, '.rb').camelize }
  end

  def generate_migrations(model_classes)
    migrations = []
    previous_models = {}
    filter = lambda { |model| models_todo.include?(model) }
    pending_models = model_classes.select(&filter)
    model_classes.reject!(&filter)

    ActiveRecord::Base.descendants.each do |model_class|
      next unless model_classes.include?(model_class.name.demodulize)

      model_class.reflect_on_all_associations(:belongs_to).each do |association|
        migration = process_association(model_class, association, previous_models)
        migrations << migration unless migration.nil?
      end
    end

    if migrations
      puts "Foreign key(s) appear to be absent from the database. " \
           "You can add it/them using the following migration(s):"
      puts migrations.join("\n")
      puts "\nTo disable this warning, add the class name(s) of the model(s) to models_todo " \
           "in #{__FILE__}"
    end

    puts "The following models are marked as todo in #{__FILE__}:"
    puts pending_models.join(", ")

    migrations
  end

  def process_association(model_class, association, previous_models)
    return if association.options[:polymorphic]

    foreign_key_table_name = determine_foreign_key_table_name(model_class, association)
    foreign_key_column = "#{association.options[:foreign_key] || association.name}_id"

    # Filter out duplicate migrations
    return if duplicate_migration?(model_class, foreign_key_table_name, previous_models)

    previous_models[model_class.table_name] ||= []
    previous_models[model_class.table_name] << foreign_key_table_name

    generate_migration(model_class, association, foreign_key_table_name, foreign_key_column)
  end

  def determine_foreign_key_table_name(model_class, association)
    if association.options[:class_name]
      class_name = association.options[:class_name].underscore.parameterize
      foreign_key_table_name = class_name.tableize
    else
      foreign_key_table_name = association.class_name.underscore.parameterize.tableize
      namespace = model_class.name.deconstantize

      unless association.class_name.deconstantize == namespace || namespace == "" ||
             ActiveRecord::Base.connection.table_exists?(foreign_key_table_name)
        foreign_key_table_name = "#{namespace.underscore}_#{foreign_key_table_name}"
      end
    end

    foreign_key_table_name
  end

  def generate_migration(model_class, _association, foreign_key_table_name, foreign_key_column)
    migration_name = "add_foreign_key_to_#{model_class.table_name}_#{foreign_key_table_name}"
    migration_class_name = migration_name.camelize

    <<~MIGRATION
      class #{migration_class_name} < ActiveRecord::Migration[6.0]
        def change
          add_foreign_key :#{model_class.table_name}, :#{foreign_key_table_name}, column: :#{foreign_key_column}
        end
      end
    MIGRATION
  end

  def duplicate_migration?(model_class, foreign_key_table_name, previous_models)
    model_class.connection.foreign_key_exists?(model_class.table_name, foreign_key_table_name) ||
      previous_models[model_class.table_name]&.include?(foreign_key_table_name)
  end
end
