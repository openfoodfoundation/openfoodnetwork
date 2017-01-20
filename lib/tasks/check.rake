namespace :openfoodnetwork do

  namespace :check do
    desc 'run stylelint'
    task stylelint: :environment do
      dir = Dir.pwd
      sh "#{dir}/node_modules/stylelint/bin/stylelint.js #{dir}/app/assets/stylesheets/**/*.scss -f verbose"
    end
  end
end
