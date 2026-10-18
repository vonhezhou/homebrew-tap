require "digest"
require "json"
require "tempfile"
require "tmpdir"

module SquirrelAppUpdater
  class Error < StandardError; end

  CASK = File.expand_path("../Casks/squirrel-app.rb", __dir__)
  API = "https://api.github.com/repos/rime/squirrel/releases/latest".freeze
  RELEASES = "https://github.com/rime/squirrel/releases/download".freeze
  VERSION = /(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)/
  VERSION_PATTERN = /^  version "(#{VERSION})"$/
  CHECKSUM_PATTERN = /^  sha256 "[0-9a-f]{64}"$/

  module_function

  def download(url, destination)
    command = ["curl", "--fail", "--location", "--silent", "--show-error",
               "--retry", "3", "--connect-timeout", "30", "--max-time", "600",
               "--proto", "=https", "--proto-redir", "=https",
               "--user-agent", "homebrew-tap-squirrel-updater", "--output", destination]
    if url == API
      command.concat(["--header", "Accept: application/vnd.github+json",
                      "--header", "X-GitHub-Api-Version: 2022-11-28"])
      token = ENV["GH_TOKEN"]
      command.concat(["--header", "Authorization: Bearer #{token}"]) if token && !token.empty?
    end
    raise Error, "Download failed for #{url}" unless system(*command, url)
  end

  def metadata(path)
    release = JSON.parse(File.read(path))
    unless release.is_a?(Hash) && release["draft"] == false && release["prerelease"] == false
      raise Error, "Upstream release is not a stable published release"
    end

    version = release["tag_name"]
    unless version.is_a?(String) && version.match?(/\A#{VERSION}\z/)
      raise Error, "Invalid upstream version"
    end

    assets = release["assets"]
    name = "Squirrel-#{version}.pkg"
    unless assets.is_a?(Array) && assets.all? { |asset| asset.is_a?(Hash) }
      raise Error, "Invalid upstream release assets"
    end
    packages = assets.select { |asset| asset["name"] == name }
    raise Error, "Cannot find unique upstream package" unless packages.length == 1

    package = packages.first
    url = "#{RELEASES}/#{version}/#{name}"
    raise Error, "Invalid official package URL" unless package["browser_download_url"] == url
    raise Error, "Upstream package is not uploaded" unless package["state"] == "uploaded"

    size = package["size"]
    raise Error, "Invalid upstream package size" unless size.is_a?(Integer) && size >= 4

    digest = package["digest"]
    unless digest.is_a?(String) && digest.match?(/\Asha256:[0-9a-f]{64}\z/)
      raise Error, "Invalid upstream SHA256 digest"
    end

    { version: version, url: url, size: size, sha256: digest.delete_prefix("sha256:") }
  rescue JSON::ParserError => error
    raise Error, "Invalid upstream JSON: #{error.message}"
  end

  def checksum(path, release)
    raise Error, "Package size does not match upstream" unless File.size(path) == release.fetch(:size)
    raise Error, "Invalid PKG archive header" unless File.binread(path, 4) == "xar!"

    digest = Digest::SHA256.file(path).hexdigest
    raise Error, "Package SHA256 does not match upstream" unless digest == release.fetch(:sha256)

    digest
  end

  def write_cask(path, original, updated)
    Tempfile.create([".squirrel-app-", ".rb"], File.dirname(path)) do |file|
      file.chmod(File.stat(path).mode & 0o777)
      file.write(updated)
      file.flush
      file.fsync
      raise Error, "Cask changed during update" unless File.read(path) == original

      File.rename(file.path, path)
    end
  end

  def run(cask_path: CASK, downloader: method(:download), output: $stdout)
    original = File.read(cask_path)
    versions = original.scan(VERSION_PATTERN)
    unless versions.length == 1 && original.scan(/^[ \t]*version\b.*$/).length == 1
      raise Error, "Cannot find unique cask version"
    end
    unless original.scan(CHECKSUM_PATTERN).length == 1 && original.scan(/^[ \t]*sha256\b.*$/).length == 1
      raise Error, "Cannot find unique cask checksum"
    end

    current = versions.first.first
    Dir.mktmpdir("squirrel-app-") do |directory|
      metadata_path = File.join(directory, "release.json")
      downloader.call(API, metadata_path)
      release = metadata(metadata_path)
      version = release.fetch(:version)
      unless (version.split(".").map(&:to_i) <=> current.split(".").map(&:to_i)) == 1
        output.puts "Squirrel #{current} is already current (upstream #{version})"
        return false
      end

      package_path = File.join(directory, "Squirrel-#{version}.pkg")
      downloader.call(release.fetch(:url), package_path)
      digest = checksum(package_path, release)
      updated = original.sub(VERSION_PATTERN, "  version \"#{version}\"")
      updated = updated.sub(CHECKSUM_PATTERN, "  sha256 \"#{digest}\"")
      write_cask(cask_path, original, updated)
      output.puts "Updated Squirrel to #{version}"
      true
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    SquirrelAppUpdater.run
  rescue StandardError => error
    abort "Squirrel update failed: #{error.message}"
  end
end
