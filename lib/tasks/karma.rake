namespace :karma  do
  task :start => :environment do |task|
    continue_only_in_test_env task
    with_tmp_config :start
  end

  task :run => :environment do |task|
    continue_only_in_test_env task
    with_tmp_config :start, "--single-run"
  end

  private

  def continue_only_in_test_env task
    if Rails.env != 'test'
      raise "Task must be called in test environment:\n  bundle exec rake #{task.name} RAILS_ENV=test"
    end
  end

  def with_tmp_config(command, args = nil)
    Tempfile.open('karma_unit.js', Rails.root.join('tmp') ) do |f|
      f.write unit_js(application_spec_files << i18n_file)
      f.flush
      trap('SIGINT') { puts "Killing Karma"; exit }
      exec "karma #{command} #{f.path} #{args}"
    end
  end

  def application_spec_files
    sprockets = Rails.application.assets
    sprockets.append_path Rails.root.join("spec/javascripts")
    Rails.application.assets.find_asset("application_spec.js").to_a.map {|e| e.pathname.to_s }
  end

  def unit_js(files)
    puts files
    unit_js = File.open('config/ng-test.conf.js', 'r').read
    unit_js.gsub "APPLICATION_SPEC", "\"#{files.join("\",\n\"")}\""
  end

  def i18n_file
    raise "I18n::JS module is missing" unless defined?(I18n::JS)
    I18n::JS::DEFAULT_EXPORT_DIR_PATH.replace('tmp/javascripts')
    I18n::JS.export
    "#{Rails.root.join(I18n::JS::DEFAULT_EXPORT_DIR_PATH)}/translations.js"
  end
end
