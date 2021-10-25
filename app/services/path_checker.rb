# frozen_string_literal: false

class PathChecker
  def initialize(fullpath, view_context)
    @fullpath = fullpath
    @view_context = view_context
  end

  def active_path?(match_path, except_paths = nil)
    root_path = @view_context.main_app.root_path
    active = @fullpath.starts_with?("#{root_path}admin#{match_path}")
    return false unless active
    return true if except_paths.blank?

    except_paths.each do |path|
      return false if @fullpath.starts_with?("#{root_path}admin#{path}")
    end

    true
  end
end
