class HandleNilVariants < ActiveRecord::Migration
   def up
     Spree::Variant.where(product_id: nil).destroy_all
     Spree::Variant.where(unit_value: [nil, Float::NAN]).find_each do |variant|
       if variant.price.nil? && variant.product.master == variant
         variant.update_column(:unit_value, 1)
       elsif !variant.valid?
         variant.update_column(:unit_value, 1)
       else
         variant.unit_value = 1
         begin
           variant.save
         rescue
           variant.update_column(:unit_value, 0)
         end
       end
     end
     Spree::Variant.where(weight: [nil, Float::NAN]).find_each do |variant|
       if variant.price.nil? && variant.product.master == variant
         variant.update_column(:weight, 0)
       elsif !variant.valid?
         variant.update_column(:weight, 0)
       else
         variant.weight = 0
         begin
           variant.save
         rescue
           variant.update_column(:weight, 0)
         end
       end
     end
     change_column_null :spree_variants, :unit_value, false, 1
     change_column_null :spree_variants, :weight, false, 0.0
     change_column_default :spree_variants, :unit_value, 1
     change_column_default :spree_variants, :weight, 0.0
     begin
       execute "ALTER TABLE spree_variants ADD CONSTRAINT check_unit_value_for_nan CHECK (unit_value <> 'NaN')"
       execute "ALTER TABLE spree_variants ADD CONSTRAINT check_weight_for_nan CHECK (weight <> 'NaN')"
     rescue ActiveRecord::StatementInvalid
       # in case the constraint already exists: do nothing
     end
   end

   def down
     change_column_null :spree_variants, :unit_value, true
     change_column_null :spree_variants, :weight, true
     change_column_default :spree_variants, :unit_value, nil
     change_column_default :spree_variants, :weight, nil
     begin
       execute "ALTER TABLE spree_variants DROP CONSTRAINT check_unit_value_for_nan"
       execute "ALTER TABLE spree_variants DROP CONSTRAINT check_weight_for_nan"
     rescue ActiveRecord::StatementInvalid
       # in case the constraint does not exist: do nothing
     end
   end
 end
