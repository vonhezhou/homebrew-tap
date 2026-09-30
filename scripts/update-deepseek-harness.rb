require "base64"
require "digest"
require "open3"
require "tmpdir"
require "yaml"

CASK = File.expand_path("../Casks/deepseek-harness.rb", __dir__)
ORIGIN = "https://download.deepseek.com"

def download(url, destination)
  system("curl", "--fail", "--location", "--silent", "--show-error",
         "--retry", "3", "--connect-timeout", "30", "--max-time", "600",
         "--proto", "=https", "--proto-redir", "=https",
         "--output", destination, url, exception: true)
end

Dir.mktmpdir("deepseek-harness-") do |directory|
  releases = %w[arm64 x64].to_h do |arch|
    feed = File.join(directory, "#{arch}.yml")
    download("#{ORIGIN}/dsh-desk/feeds/mac-#{arch}/nightly-mac.yml", feed)
    metadata = YAML.safe_load(File.read(feed))
    version = metadata.fetch("version")
    abort "Invalid upstream version" unless version.is_a?(String) && version.match?(/\A\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?\z/)

    url = "#{ORIGIN}/dsh-desk/bin/mac-#{arch}/deepseek-harness-#{version}-mac-#{arch}.zip"
    asset = metadata.fetch("files").find { |file| file.fetch("url") == url }
    abort "Missing versioned #{arch} ZIP in upstream feed" unless asset
    checksum = Base64.strict_decode64(asset.fetch("sha512"))
    abort "Invalid upstream SHA-512" unless checksum.bytesize == 64
    [arch, { version: version, url: url, checksum: checksum, size: asset.fetch("size") }]
  end

  versions = releases.values.map { |release| release.fetch(:version) }.uniq
  abort "Architecture versions differ; retry after upstream publication completes" unless versions.length == 1
  version = versions.first
  original = File.read(CASK)
  current = original.match(/^  version "([^"]+)"$/)&.captures&.first
  abort "Cannot find current cask version" unless current
  if current == version
    puts "DeepSeek Harness #{version} is already current"
    exit
  end

  checksums = releases.to_h do |arch, release|
    archive = File.join(directory, "#{arch}.zip")
    download(release.fetch(:url), archive)
    abort "Size mismatch for #{arch}" unless File.size(archive) == release.fetch(:size)
    abort "SHA-512 mismatch for #{arch}" unless Digest::SHA512.file(archive).digest == release.fetch(:checksum)
    plist, status = Open3.capture2("unzip", "-p", archive, "DeepSeek Harness.app/Contents/Info.plist")
    abort "Missing app bundle for #{arch}" unless status.success?
    bundle_version = plist[/<key>CFBundleShortVersionString<\/key>\s*<string>([^<]+)<\/string>/, 1]
    abort "Bundle version mismatch for #{arch}" unless bundle_version == version
    [arch, Digest::SHA256.file(archive).hexdigest]
  end

  updated = original.sub(/^  version "[^"]+"$/, "  version \"#{version}\"")
  %w[arm64 x64].each do |arch|
    key = arch == "arm64" ? "arm" : "intel"
    pattern = /(\b#{key}:\s+")[0-9a-f]{64}("[,\n])/
    abort "Cannot find #{key} checksum" unless updated.match?(pattern)
    updated = updated.sub(pattern) { "#{$1}#{checksums.fetch(arch)}#{$2}" }
  end
  File.write(CASK, updated)
  puts "Updated DeepSeek Harness to #{version}"
end
