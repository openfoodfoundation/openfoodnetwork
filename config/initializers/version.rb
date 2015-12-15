module GitRepo
  def self.last_tag
    begin
      IO.popen("git describe --tags --abbrev=0 "){ |v| v.readline.strip }
    rescue
      I18n.t(:version_not_found)
    end
  end
end

module OpenFoodNetwork
  VERSION = GitRepo.last_tag
end

