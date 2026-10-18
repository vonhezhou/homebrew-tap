require "digest"
require "json"
require "tempfile"
require "tmpdir"

module NeteaseMusicUpdater
  class Error < StandardError; end

  CASK = File.expand_path("../Casks/neteasemusic.rb", __dir__)
  ARCHITECTURES = %w[arm64 x86_64].freeze
  API = "https://music.163.com/api/mac/package/download/latest".freeze
  ORIGIN = "https://d1.music.126.net/dmusic".freeze
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15".freeze
  MIN_DMG_SIZE = 1024 * 1024
  VERSION_PATTERN = /^  version "(\d+\.\d+\.\d+,\d+)"$/
  CHECKSUM_PATTERN = /^  sha256 arm:[ \t]+"[0-9a-f]{64}",\n[ \t]+intel:[ \t]+"[0-9a-f]{64}"$/

  module_function

  def download(url, destination)
    success = system("curl", "--fail", "--location", "--silent", "--show-error",
                     "--retry", "3", "--connect-timeout", "30", "--max-time", "600",
                     "--proto", "=https", "--proto-redir", "=https",
                     "--user-agent", USER_AGENT, "--output", destination, url)
    raise Error, "Download failed for #{url}" unless success
  end

  def metadata(path, architecture)
    response = JSON.parse(File.read(path))
    unless response.is_a?(Hash) && response["code"] == 200 && response["data"].is_a?(Hash)
      raise Error, "Invalid upstream response for #{architecture}"
    end

    data = response["data"]
    app_version = data["appVer"]
    build_version = data["buildVer"]
    unless app_version.is_a?(String) && app_version.match?(/\A\d+\.\d+\.\d+\z/) &&
           build_version.is_a?(String) && build_version.match?(/\A\d+\z/)
      raise Error, "Invalid upstream version for #{architecture}"
    end

    expected_url = "#{ORIGIN}/NeteaseCloudMusic_Music_official_#{app_version}.#{build_version}_#{architecture}.dmg"
    raise Error, "Invalid versioned download URL for #{architecture}" unless data["downloadUrl"] == expected_url

    { version: "#{app_version},#{build_version}", url: expected_url }
  rescue JSON::ParserError => error
    raise Error, "Invalid upstream JSON for #{architecture}: #{error.message}"
  end

  def version_numbers(version)
    version.split(/[.,]/).map(&:to_i)
  end

  def checksum(path, architecture)
    raise Error, "DMG is too small for #{architecture}" if File.size(path) < MIN_DMG_SIZE

    signature = File.open(path, "rb") do |file|
      file.seek(-512, IO::SEEK_END)
      file.read(4)
    end
    raise Error, "Invalid DMG trailer for #{architecture}" unless signature == "koly"

    Digest::SHA256.file(path).hexdigest
  end

  def write_cask(path, original, updated)
    raise Error, "Cask changed during update" unless File.read(path) == original

    Tempfile.create([".neteasemusic-", ".rb"], File.dirname(path)) do |file|
      file.chmod(File.stat(path).mode & 0o777)
      file.write(updated)
      file.flush
      file.fsync
      File.rename(file.path, path)
    end
  end

  def run(cask_path: CASK, downloader: method(:download), output: $stdout)
    original = File.read(cask_path)
    versions = original.scan(VERSION_PATTERN)
    raise Error, "Cannot find unique cask version" unless versions.length == 1
    raise Error, "Cannot find unique architecture checksums" unless original.scan(CHECKSUM_PATTERN).length == 1

    current = versions.first.first
    Dir.mktmpdir("neteasemusic-") do |directory|
      releases = ARCHITECTURES.map do |architecture|
        path = File.join(directory, "#{architecture}.json")
        downloader.call("#{API}?arch=#{architecture}&productName=music", path)
        metadata(path, architecture)
      end
      version = releases.first.fetch(:version)
      raise Error, "Upstream architecture versions do not match" unless releases.all? { |release| release.fetch(:version) == version }

      unless (version_numbers(version) <=> version_numbers(current)) == 1
        output.puts "NetEase Cloud Music #{current} is already current (upstream #{version})"
        return false
      end

      checksums = ARCHITECTURES.zip(releases).map do |architecture, release|
        path = File.join(directory, "#{architecture}.dmg")
        downloader.call(release.fetch(:url), path)
        checksum(path, architecture)
      end
      updated = original.sub(VERSION_PATTERN, "  version \"#{version}\"")
      updated = updated.sub(CHECKSUM_PATTERN, "  sha256 arm:   \"#{checksums[0]}\",\n         intel: \"#{checksums[1]}\"")
      write_cask(cask_path, original, updated)
      output.puts "Updated NetEase Cloud Music to #{version}"
      true
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    NeteaseMusicUpdater.run
  rescue StandardError => error
    abort "NetEase Cloud Music update failed: #{error.message}"
  end
end
