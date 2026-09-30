require "base64"
require "digest"
require "tmpdir"
require "yaml"

CASK = File.expand_path("../Casks/kimi-code.rb", __dir__)
ORIGIN = "https://code.kimi.com/kimi-code/desktop"

def download(url, destination)
  system("curl", "--fail", "--location", "--silent", "--show-error",
         "--retry", "3", "--connect-timeout", "30", "--max-time", "600",
         "--proto", "=https", "--proto-redir", "=https",
         "--output", destination, url, exception: true)
end

Dir.mktmpdir("kimi-code-") do |directory|
  feed = File.join(directory, "latest-mac.yml")
  download("#{ORIGIN}/latest-mac.yml", feed)
  metadata = YAML.safe_load(File.read(feed))
  version = metadata.fetch("version")
  abort "Invalid upstream version" unless version.is_a?(String) && version.match?(/\A\d+\.\d+\.\d+\z/)

  original = File.read(CASK)
  current = original.match(/^  version "([^"]+)"$/)&.captures&.first
  abort "Cannot find current cask version" unless current
  if current == version
    puts "Kimi Code #{version} is already current"
    exit
  end

  path = "binaries/#{version}/KimiCode-#{version}-mac-arm64.dmg"
  asset = metadata.fetch("files").find { |file| file.fetch("url") == path }
  abort "Missing versioned arm64 DMG in upstream feed" unless asset
  checksum = Base64.strict_decode64(asset.fetch("sha512"))
  abort "Invalid upstream SHA-512" unless checksum.bytesize == 64
  archive = File.join(directory, "arm64.dmg")
  download("#{ORIGIN}/#{path}", archive)
  abort "Size mismatch for arm64" unless File.size(archive) == asset.fetch("size")
  abort "SHA-512 mismatch for arm64" unless Digest::SHA512.file(archive).digest == checksum
  sha256 = Digest::SHA256.file(archive).hexdigest

  updated = original.sub(/^  version "[^"]+"$/, "  version \"#{version}\"")
  pattern = /^  sha256 "[0-9a-f]{64}"$/
  abort "Cannot find arm64 checksum" unless updated.match?(pattern)
  updated = updated.sub(pattern, "  sha256 \"#{sha256}\"")
  File.write(CASK, updated)
  puts "Updated Kimi Code to #{version}"
end
