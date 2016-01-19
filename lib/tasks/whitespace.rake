namespace :whitespace do
  desc 'Removes trailing whitespace'
  task :cleanup do
    sh %{for f in `find . -type f | grep -v .git | grep -v ./vendor | grep -v ./tmp | egrep ".(rb|js|haml|html|css|sass)"`;
          do sed -i '' 's/ *$//g' "$f";
        done}, {:verbose => false}
    puts "Task cleanup done"
  end

  desc 'Converts hard-tabs into two-space soft-tabs'
  task :retab do
    sh %{for f in `find . -type f | grep -v .git | grep -v ./vendor | grep -v ./tmp | egrep ".(rb|js|haml|html|css|sass)"`;
          do sed -i '' 's/\t/  /g' "$f";
        done}, {:verbose => false}
    puts "Task retab done"
  end

  desc 'Remove consecutive blank lines'
  task :scrub_gratuitous_newlines do
    sh %{for f in `find . -type f | grep -v .git | grep -v ./vendor | grep -v ./tmp | egrep ".(rb|js|haml|html|css|sass)"`;
          do sed -i '' '/./,/^$/!d' "$f";
        done}, {:verbose => false}
    puts "Task scrub_gratuitous_newlines done"
  end

  desc 'Execute all WHITESPACE tasks'
  task :all do
    Rake::Task['whitespace:cleanup'].execute
    Rake::Task['whitespace:retab'].execute
    Rake::Task['whitespace:scrub_gratuitous_newlines'].execute
  end
end
