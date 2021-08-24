# frozen_string_literal: true

module DownloadsHelper
  TIMEOUT = 10

  def self.path
    Rails.root.join("tmp", "downloads")
  end

  def downloaded_filename
    wait_for_download
    downloaded_filenames.first
  end

  def downloaded_content
    wait_for_download
    File.read(downloaded_filename)
  end

  def with_empty_downloads_folder
    remove_downloaded_files
    yield
    remove_downloaded_files
  end

  private

  def downloaded_filenames
    Dir[DownloadsHelper.path.join("*")]
  end

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.1 until downloaded?
    end
  end

  def downloaded?
    !downloading? && downloaded_filenames.any?
  end

  def downloading?
    downloaded_filenames.grep(/\.crdownload$/).any?
  end

  def remove_downloaded_files
    FileUtils.rm_f(downloaded_filenames)
  end
end
