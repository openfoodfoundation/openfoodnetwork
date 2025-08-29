# frozen_string_literal: true

# A shared context for all rake specs
shared_context "rake" do
  before(:all) do
    # Make sure that Rake tasks are only loaded once.
    # Otherwise we lose code coverage data.
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  # Use the same task string as you would on the command line.
  #
  # ```rb
  # invoke_task "example:task[arg1,arg2]"
  # ```
  #
  # This helper makes sure that you can run a task multiple times,
  # even within the same test example.
  def invoke_task(task_string)
    Rake.application.invoke_task(task_string)
  ensure
    name, _args = Rake.application.parse_task_string(task_string)
    Rake::Task[name].reenable
  end
end
