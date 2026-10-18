require "minitest/autorun"
require "stringio"
require_relative "../scripts/update-neteasemusic"

class NeteaseMusicUpdaterTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir("neteasemusic-test-")
    @cask = File.join(@directory, "neteasemusic.rb")
    @original = <<~RUBY
      cask "neteasemusic" do
        arch arm: "arm64", intel: "x86_64"

        version "3.1.13,3451"
        sha256 arm:   "#{'a' * 64}",
               intel: "#{'b' * 64}"

        url "https://d1.music.126.net/dmusic/NeteaseCloudMusic_Music_official_\#{version.csv.first}.\#{version.csv.second}_\#{arch}.dmg"
      end
    RUBY
    File.write(@cask, @original)
    @releases = {}
    @archives = {}
    @calls = []
    NeteaseMusicUpdater::ARCHITECTURES.each do |architecture|
      @releases[architecture] = release(architecture)
      @archives[architecture] = architecture.ljust(NeteaseMusicUpdater::MIN_DMG_SIZE - 512, "\0") + "koly" + "\0" * 508
    end
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def release(architecture, app_version = "3.1.14", build_version = "3452")
    {
      "code" => 200,
      "data" => {
        "appVer" => app_version,
        "buildVer" => build_version,
        "downloadUrl" => "#{NeteaseMusicUpdater::ORIGIN}/NeteaseCloudMusic_Music_official_#{app_version}.#{build_version}_#{architecture}.dmg"
      }
    }
  end

  def run_update
    NeteaseMusicUpdater.run(cask_path: @cask, downloader: method(:download), output: StringIO.new)
  end

  def download(url, destination)
    @calls << url
    architecture = url.include?("arm64") ? "arm64" : "x86_64"
    if url.start_with?(NeteaseMusicUpdater::API + "?")
      File.write(destination, JSON.generate(@releases.fetch(architecture)))
    else
      archive = @archives.fetch(architecture)
      raise NeteaseMusicUpdater::Error, "Simulated download failure" if archive == :failure

      File.binwrite(destination, archive)
    end
  end

  def assert_rejected
    assert_raises(NeteaseMusicUpdater::Error) { run_update }
    assert_equal @original, File.read(@cask)
  end

  def test_updates_both_architectures_after_successful_downloads
    assert_equal true, run_update

    expected = @original.sub('version "3.1.13,3451"', 'version "3.1.14,3452"')
    expected = expected.sub("a" * 64, Digest::SHA256.hexdigest(@archives.fetch("arm64")))
    expected = expected.sub("b" * 64, Digest::SHA256.hexdigest(@archives.fetch("x86_64")))
    assert_equal expected, File.read(@cask)
    assert_equal 4, @calls.length
  end

  def test_same_version_does_not_download_archives_or_write_cask
    @releases.transform_values!.with_index { |_value, index| release(NeteaseMusicUpdater::ARCHITECTURES[index], "3.1.13", "3451") }

    assert_equal false, run_update
    assert_equal @original, File.read(@cask)
    assert_equal 2, @calls.length
    assert @calls.all? { |url| url.start_with?(NeteaseMusicUpdater::API + "?") }
  end

  def test_accepts_single_space_checksums_and_normalizes_homebrew_alignment
    File.write(@cask, @original.sub("sha256 arm:   ", "sha256 arm: "))

    assert_equal true, run_update
    updated = File.read(@cask)
    assert_match(/^  sha256 arm:   "[0-9a-f]{64}",\n         intel: "[0-9a-f]{64}"$/, updated)
  end

  def test_older_version_does_not_download_archives_or_write_cask
    @releases.keys.each { |architecture| @releases[architecture] = release(architecture, "3.1.12", "9999") }

    assert_equal false, run_update
    assert_equal @original, File.read(@cask)
    assert_equal 2, @calls.length
  end

  def test_compares_build_numbers_numerically
    @original = @original.sub("3.1.13,3451", "3.1.14,999")
    File.write(@cask, @original)
    @releases.keys.each { |architecture| @releases[architecture] = release(architecture, "3.1.14", "1000") }

    assert_equal true, run_update
    assert_includes File.read(@cask), 'version "3.1.14,1000"'
  end

  def test_missing_architecture_response_keeps_cask_unchanged
    @releases["x86_64"] = { "code" => 404 }
    assert_rejected
    assert_equal 2, @calls.length
  end

  def test_mismatched_architecture_versions_keep_cask_unchanged
    @releases["x86_64"] = release("x86_64", "3.1.14", "3453")
    assert_rejected
    assert_equal 2, @calls.length
  end

  def test_invalid_version_keeps_cask_unchanged
    @releases["arm64"]["data"]["appVer"] = "3.1.14-beta"
    assert_rejected
  end

  def test_nonofficial_download_url_keeps_cask_unchanged
    @releases["arm64"]["data"]["downloadUrl"].sub!("d1.music.126.net", "example.com")
    assert_rejected
  end

  def test_unversioned_download_url_keeps_cask_unchanged
    @releases["arm64"]["data"]["downloadUrl"] = "#{NeteaseMusicUpdater::ORIGIN}/latest_arm64.dmg"
    assert_rejected
  end

  def test_wrong_architecture_download_url_keeps_cask_unchanged
    @releases["arm64"]["data"]["downloadUrl"].sub!("_arm64.dmg", "_x86_64.dmg")
    assert_rejected
  end

  def test_wrong_version_download_url_keeps_cask_unchanged
    @releases["arm64"]["data"]["downloadUrl"].sub!("3.1.14.3452", "3.1.13.3451")
    assert_rejected
  end

  def test_second_download_failure_keeps_cask_unchanged
    @archives["x86_64"] = :failure
    assert_rejected
    assert_equal 4, @calls.length
  end

  def test_small_download_keeps_cask_unchanged
    @archives["x86_64"] = "<html>Upstream error</html>"
    assert_rejected
  end

  def test_large_html_download_keeps_cask_unchanged
    @archives["x86_64"] = "<html>Upstream error</html>".ljust(NeteaseMusicUpdater::MIN_DMG_SIZE, " ")
    assert_rejected
  end

  def test_missing_checksum_keeps_cask_unchanged_without_network
    @original = @original.sub(/\n[ ]+intel: "b+"/, "")
    File.write(@cask, @original)
    assert_rejected
    assert_empty @calls
  end

  def test_duplicate_version_keeps_cask_unchanged_without_network
    @original += "  version \"3.1.13,3451\"\n"
    File.write(@cask, @original)
    assert_rejected
    assert_empty @calls
  end
end
