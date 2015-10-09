namespace :karma  do
  task :start => :environment do
    with_tmp_config :start
  end

  task :run => :environment do
    with_tmp_config :start, "--single-run"
  end

  private

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
    files = Rails.application.assets.find_asset("application_spec.js").to_a.map {|e| e.pathname.to_s }
  end

  def unit_js(files)
    puts files
    unit_js = File.open('config/ng-test.conf.js', 'r').read
    unit_js.gsub "APPLICATION_SPEC", "\"#{files.join("\",\n\"")}\""
  end

  def i18n_file
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    f = Tempfile.open('i18n.js', Rails.root.join('tmp') )
    f.write 'window.I18n = '
    f.write I18n.backend.send(:translations)[I18n.locale].with_indifferent_access.to_json.html_safe
    f.flush
    f.path
  end
end
