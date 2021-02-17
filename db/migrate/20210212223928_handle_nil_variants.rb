class HandleNilVariants < ActiveRecord::Migration
   def up
     Spree::Variant.where(product_id: nil).destroy_all
     Spree::Variant.where(unit_value: [nil, Float::NAN]).find_each do |variant|
       if can_update_with_callbacks?(variant)
         variant.unit_value = 1
         begin
           variant.save
         rescue
           variant.update_column(:unit_value, 1)
         end
       else
         variant.update_column(:unit_value, 1)
       end
     end
     Spree::Variant.where(weight: Float::NAN).find_each do |variant|
       if can_update_with_callbacks?(variant)
         variant.weight = 0
         begin
           variant.save
         rescue
           variant.update_column(:weight, 0)
         end
       else
         variant.update_column(:weight, 0)
       end
     end
     change_column_null :spree_variants, :unit_value, false, 1
     change_column_default :spree_variants, :unit_value, 1
     change_column_default :spree_variants, :weight, 0.0

     if !constraint_present?("check_unit_value_for_nan")
       execute "ALTER TABLE spree_variants ADD CONSTRAINT check_unit_value_for_nan CHECK (unit_value <> 'NaN')"
     end
     if !constraint_present?("check_weight_for_nan")
       execute "ALTER TABLE spree_variants ADD CONSTRAINT check_weight_for_nan CHECK (weight <> 'NaN')"
     end
   end

   def down
     change_column_null :spree_variants, :unit_value, true
     change_column_default :spree_variants, :unit_value, nil
     change_column_default :spree_variants, :weight, nil
     if constraint_present?("check_unit_value_for_nan")
       execute "ALTER TABLE spree_variants DROP CONSTRAINT check_unit_value_for_nan"
     end
     if constraint_present?("check_weight_for_nan")
       execute "ALTER TABLE spree_variants DROP CONSTRAINT check_weight_for_nan"
     end
   end

   private

   def can_update_with_callbacks?(variant)
     return false if variant.price.nil? && variant.product.master == variant

     variant.valid?
   end

   def constraint_present?(name)
     ActiveRecord::Base.connection.execute("SELECT con.* FROM pg_catalog.pg_constraint con INNER JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace AND rel.relname = 'spree_variants' WHERE conname = '#{name}';").values.present?
   end
 end
