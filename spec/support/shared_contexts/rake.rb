# frozen_string_literal: true

# Let this context take care of Rake testing gotchas.
#
# ```rb
# RSpec.describe "my_task.rake" do
#   include_context "rake"
#   # ..
# ```
#
shared_context "rake" do
  before(:all) do
    # Make sure that Rake tasks are only loaded once.
    # Otherwise we lose code coverage data.
    if Rake::Task.tasks.empty?
      Openfoodnetwork::Application.load_tasks
      Rake::Task.define_task(:environment)
    end
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
