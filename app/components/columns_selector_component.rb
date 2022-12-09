# frozen_string_literal: true

class ColumnsSelectorComponent < MultipleCheckedSelectComponent
  def initialize(columns:)
    super(name: I18n.t('components.columns_selector.title'),
          options: columns.map { |c| [c.name, c.id] },
          selected: columns.select(&:visible).map(&:id))
  end
end
