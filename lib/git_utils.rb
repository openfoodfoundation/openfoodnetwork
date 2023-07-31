# frozen_string_literal: true

class GitUtils
  # Generate a description of the git version based on latest tag.
  # Eg: "v4.4.4-156-g8afcd82-modified"
  #  - tag name
  #  - number of commits since tag
  #  - commit ID
  #  - "modified" if uncommitted changes
  #
  def self.git_version
    # Capture stderr so that confusing errors aren't shown in comand output
    stdout, _stderr, _status = Open3.capture3("git describe --tags --dirty=-modified")
    # Strip trailing linebreak
    stdout.strip
  end
end
