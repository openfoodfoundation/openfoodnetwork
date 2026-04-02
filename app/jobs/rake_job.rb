# frozen_string_literal: true

require "rake"

# Executes a rake task
class RakeJob < ApplicationJob
  def perform(task_string)
    Rails.application.load_tasks if Rake::Task.tasks.empty?

    Rake.application.invoke_task(task_string)
  ensure
    name, _args = Rake.application.parse_task_string(task_string)
    Rake::Task[name].reenable
  end
end
