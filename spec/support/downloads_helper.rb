module DownloadsHelper
  TIMEOUT = 10
  PATH    = Rails.root.join("tmp", "downloads")

  def downloaded_filename
    wait_for_download
    downloaded_filenames.first
  end

  def downloaded_content
    wait_for_download
    File.read(downloaded_filename)
  end

  def clear_downloads
    FileUtils.rm_f(downloaded_filenames)
  end

  private

  def downloaded_filenames
    Dir[PATH.join("*")]
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
end
