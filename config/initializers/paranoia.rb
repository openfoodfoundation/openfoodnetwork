module Paranoia
  def paranoia_delete
    raise ActiveRecord::ReadOnlyRecord, "#{self.class} is marked as readonly" if readonly?
    if persisted?
      # if a transaction exists, add the record so that after_commit
      # callbacks can be run
      add_to_transaction unless self.class.connection.current_transaction.closed?
      update_columns(paranoia_destroy_attributes)
    elsif !frozen?
      assign_attributes(paranoia_destroy_attributes)
    end
    self
  end
  alias_method :delete, :paranoia_delete
end
