# frozen_string_literal: true

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
      .map do |file|
        relative_path = Pathname.new(file).relative_path_from(Rails.root.join('app/models')).to_s
        subdirectory = File.dirname(relative_path)
        base_name = File.basename(file, '.rb').camelize
        subdirectory == "." ? base_name : "#{subdirectory.camelize}::#{base_name}"
      end
  end

  def generate_migrations(model_classes)
    migrations = []
    filter = lambda { |model| models_todo.include?(model) }
    pending_models = model_classes.select(&filter)
    model_classes.reject!(&filter)

    ActiveRecord::Base.descendants.each do |model_class|
      next unless model_classes.include?(model_class.name)

      model_class.reflect_on_all_associations(:belongs_to).each do |association|
        migration = process_association(model_class, association)
        migrations << migration unless migration.nil?
      end
    end

    print_missing_foreign_key_warnings(migrations)

    puts "The following models are marked as todo in #{__FILE__}:"
    puts pending_models.join(", ")

    migrations
  end

  def print_missing_foreign_key_warnings(migrations)
    return if migrations.empty?

    puts "Foreign key(s) appear to be absent from the database. " \
         "You can add it/them using the following migration(s):"
    puts migrations.join("\n")
    puts "\nTo disable this warning, add the class name(s) of the model(s) to models_todo " \
         "in #{__FILE__}"
  end

  def process_association(model_class, association)
    return if association.options[:polymorphic] || association.options[:optional]

    foreign_key_table_name = determine_foreign_key_table_name(model_class, association)
    foreign_key_column = association.options[:foreign_key] || "#{association.name}_id"
    foreign_keys = model_class.connection.foreign_keys(model_class.table_name)

    # Check if there is a foreign key that already exists for the column
    return if foreign_keys.any? { |fk|
                fk.column == foreign_key_column &&
                fk.to_table == foreign_key_table_name
              }

    generate_migration(model_class, foreign_key_table_name, foreign_key_column)
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

  def generate_migration(model_class, foreign_key_table_name, foreign_key_column)
    migration_name = "add_foreign_key_to_#{model_class.table_name}_" \
                     "#{foreign_key_table_name}_#{foreign_key_column}"
    migration_class_name = migration_name.camelize
    orphaned_records_query = generate_orphaned_records_query(model_class, foreign_key_table_name,
                                                             foreign_key_column)

    <<~MIGRATION
      # Orphaned records can be found before running this migration with the following SQL:

      #{orphaned_records_query}

      class #{migration_class_name} < ActiveRecord::Migration[6.0]
        def change
          add_foreign_key :#{model_class.table_name}, :#{foreign_key_table_name}, column: :#{foreign_key_column}
        end
      end
    MIGRATION
  end

  def generate_orphaned_records_query(model_class, foreign_key_table_name, foreign_key_column)
    <<~SQL # rubocop:disable Rails/SquishedSQLHeredocs # Using squish deletes the newlines
      # SELECT COUNT(*)
      # FROM #{model_class.table_name}
      # LEFT JOIN #{foreign_key_table_name}
      #   ON #{model_class.table_name}.#{foreign_key_column} = #{foreign_key_table_name}.id
      # WHERE #{foreign_key_table_name}.id IS NULL
      #   AND #{model_class.table_name}.#{foreign_key_column} IS NOT NULL
    SQL
  end
end
