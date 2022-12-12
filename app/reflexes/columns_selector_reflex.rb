# frozen_string_literal: true

class ColumnsSelectorReflex < ApplicationReflex
  def save
    load_collection
    @cp_set.collection.each { |cp| authorize! :bulk_update, cp }

    if @cp_set.save
      flash[:success] = I18n.t("admin.reflexes.columns_selector.save.sucess" )
      morph "#listing_order_cycles", render(partial: "admin/order_cycles/listing_order_cycles_table")
    elsif @cp_set.errors.present?
      flash[:error] = I18n.t("admin.reflexes.columns_selector.save.fail" )
    end
    morph "#flashes", render(partial: "shared/flashes", locals: { flashes: flash })
  end

  def load_collection
    all_columns = ColumnPreference.where(user_id: current_user.id,
                                         action_name: element.dataset["action-name"])
    all_columns.each { |cp| cp.visible = false }
    columns_to_be_visible = all_columns.select { |c| params[:columns].include?(c.id.to_s) }
    columns_to_be_visible.each{ |cp| cp.visible = true }

    @cp_set = Sets::ColumnPreferenceSet.new(all_columns)
  end
end
