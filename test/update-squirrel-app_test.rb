require "minitest/autorun"
require "stringio"
require_relative "../scripts/update-squirrel-app"

class SquirrelAppUpdaterTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir("squirrel-app-test-")
    @cask = File.join(@directory, "squirrel-app.rb")
    @original = <<~RUBY
      cask "squirrel-app" do
        version "1.1.2"
        sha256 "#{'a' * 64}"

        url "https://github.com/rime/squirrel/releases/download/\#{version}/Squirrel-\#{version}.pkg"
        pkg "Squirrel-\#{version}.pkg"
      end
    RUBY
    File.write(@cask, @original)
    @archive = "xar!test package bytes"
    @release = release("1.1.3")
    @calls = []
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def release(version)
    {
      "tag_name" => version,
      "draft" => false,
      "prerelease" => false,
      "assets" => [{
        "name" => "Squirrel-#{version}.pkg",
        "browser_download_url" => "#{SquirrelAppUpdater::RELEASES}/#{version}/Squirrel-#{version}.pkg",
        "state" => "uploaded",
        "size" => @archive.bytesize,
        "digest" => "sha256:#{Digest::SHA256.hexdigest(@archive)}"
      }]
    }
  end

  def package
    @release.fetch("assets").first
  end

  def download(url, destination)
    @calls << url
    raise SquirrelAppUpdater::Error, "Simulated download failure" if url == @failed_url

    if url == SquirrelAppUpdater::API
      File.write(destination, @json || JSON.generate(@release))
    else
      File.binwrite(destination, @archive)
    end
  end

  def run_update
    SquirrelAppUpdater.run(cask_path: @cask, downloader: method(:download), output: StringIO.new)
  end

  def assert_rejected
    assert_raises(SquirrelAppUpdater::Error) { run_update }
    assert_equal @original, File.read(@cask)
  end

  def test_updates_version_and_checksum_after_verified_package_download
    assert_equal true, run_update
    expected = @original.sub('version "1.1.2"', 'version "1.1.3"')
    expected = expected.sub("a" * 64, Digest::SHA256.hexdigest(@archive))
    assert_equal expected, File.read(@cask)
    assert_equal [SquirrelAppUpdater::API, package.fetch("browser_download_url")], @calls
  end

  def test_compares_versions_numerically
    @original = @original.sub('version "1.1.2"', 'version "1.9.9"')
    File.write(@cask, @original)
    @release = release("1.10.0")
    assert_equal true, run_update
    assert_includes File.read(@cask), 'version "1.10.0"'
  end

  def test_same_version_does_not_download_package_or_update_cask
    @release = release("1.1.2")
    assert_equal false, run_update
    assert_equal @original, File.read(@cask)
    assert_equal [SquirrelAppUpdater::API], @calls
  end

  def test_older_version_does_not_download_package_or_update_cask
    @release = release("1.1.1")
    assert_equal false, run_update
    assert_equal @original, File.read(@cask)
    assert_equal [SquirrelAppUpdater::API], @calls
  end

  def test_draft_is_rejected
    @release["draft"] = true
    assert_rejected
  end

  def test_prerelease_is_rejected
    @release["prerelease"] = true
    assert_rejected
  end

  def test_missing_stability_flag_is_rejected
    @release.delete("prerelease")
    assert_rejected
  end

  def test_invalid_version_is_rejected
    @release["tag_name"] = "1.1.3-beta"
    assert_rejected
  end

  def test_noncanonical_version_is_rejected
    @release["tag_name"] = "01.1.3"
    assert_rejected
  end

  def test_missing_package_is_rejected
    @release["assets"] = []
    assert_rejected
  end

  def test_duplicate_package_is_rejected
    @release["assets"] << package.dup
    assert_rejected
  end

  def test_invalid_asset_type_is_rejected
    @release["assets"] = [nil]
    assert_rejected
  end

  def test_nonofficial_url_is_rejected
    package["browser_download_url"].sub!("github.com", "example.com")
    assert_rejected
  end

  def test_wrong_version_url_is_rejected
    package["browser_download_url"].sub!("/1.1.3/", "/1.1.2/")
    assert_rejected
  end

  def test_unversioned_url_is_rejected
    package["browser_download_url"] = "https://github.com/rime/squirrel/releases/latest/download/Squirrel.pkg"
    assert_rejected
  end

  def test_unuploaded_asset_is_rejected
    package["state"] = "new"
    assert_rejected
  end

  def test_missing_upstream_digest_is_rejected
    package.delete("digest")
    assert_rejected
  end

  def test_wrong_digest_algorithm_is_rejected
    package["digest"] = "sha512:#{'a' * 64}"
    assert_rejected
  end

  def test_invalid_digest_hex_is_rejected
    package["digest"] = "sha256:#{'z' * 64}"
    assert_rejected
  end

  def test_invalid_size_is_rejected
    package["size"] = @archive.bytesize.to_s
    assert_rejected
  end

  def test_metadata_download_failure_keeps_cask_unchanged
    @failed_url = SquirrelAppUpdater::API
    assert_rejected
  end

  def test_invalid_json_keeps_cask_unchanged
    @json = "<html>Service unavailable</html>"
    assert_rejected
  end

  def test_package_download_failure_keeps_cask_unchanged
    @failed_url = package.fetch("browser_download_url")
    assert_rejected
    assert_equal 2, @calls.length
  end

  def test_wrong_package_size_keeps_cask_unchanged
    @archive += "truncated or unexpected response"
    assert_rejected
  end

  def test_wrong_package_digest_keeps_cask_unchanged
    @archive[-1] = "!"
    assert_rejected
  end

  def test_non_pkg_download_with_matching_size_and_digest_is_rejected
    @archive = "<html>error</html>"
    @release = release("1.1.3")
    assert_rejected
  end

  def test_missing_checksum_keeps_cask_unchanged_without_network
    @original = @original.sub(/^  sha256.*\n/, "")
    File.write(@cask, @original)
    assert_rejected
    assert_empty @calls
  end

  def test_invalid_checksum_keeps_cask_unchanged_without_network
    @original = @original.sub("a" * 64, "bad-digest")
    File.write(@cask, @original)
    assert_rejected
    assert_empty @calls
  end

  def test_duplicate_checksum_keeps_cask_unchanged_without_network
    @original += "  sha256 \"#{'b' * 64}\"\n"
    File.write(@cask, @original)
    assert_rejected
    assert_empty @calls
  end

  def test_duplicate_version_keeps_cask_unchanged_without_network
    @original += "  version \"1.1.2\"\n"
    File.write(@cask, @original)
    assert_rejected
    assert_empty @calls
  end

  def test_invalid_cask_version_keeps_cask_unchanged_without_network
    @original = @original.sub('version "1.1.2"', 'version :latest')
    File.write(@cask, @original)
    assert_rejected
    assert_empty @calls
  end

  def test_concurrent_cask_change_is_preserved
    changed = @original + "# User change\n"
    downloader = lambda do |url, destination|
      download(url, destination)
      File.write(@cask, changed) unless url == SquirrelAppUpdater::API
    end
    assert_raises(SquirrelAppUpdater::Error) do
      SquirrelAppUpdater.run(cask_path: @cask, downloader: downloader, output: StringIO.new)
    end
    assert_equal changed, File.read(@cask)
  end

  def test_authentication_is_only_sent_to_the_metadata_api
    commands = []
    previous_token = ENV["GH_TOKEN"]
    ENV["GH_TOKEN"] = "test-github-token"
    SquirrelAppUpdater.stub(:system, lambda { |*arguments| commands << arguments; true }) do
      SquirrelAppUpdater.download(SquirrelAppUpdater::API, "/tmp/release.json")
      SquirrelAppUpdater.download(package.fetch("browser_download_url"), "/tmp/package.pkg")
    end
    assert_includes commands.first, "Authorization: Bearer test-github-token"
    refute commands.last.any? { |argument| argument.include?("test-github-token") }
  ensure
    ENV["GH_TOKEN"] = previous_token
  end
end
