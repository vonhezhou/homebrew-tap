cask "neteasemusic" do
  arch arm: "arm64", intel: "x86_64"

  version "3.1.14,3459"
  sha256 arm:   "fb4c990c7c92451600945441c9a8ecd8b456427b33f93000f5fb21e6fc7d4df5",
         intel: "facfcc644c6ad931d376294d88d27746a3279d12e5ecb796213bec5423d93395"

  url "https://d1.music.126.net/dmusic/NeteaseCloudMusic_Music_official_#{version.csv.first}.#{version.csv.second}_#{arch}.dmg",
      user_agent: :browser
  name "NetEase Cloud Music"
  name "网易云音乐"
  desc "Music streaming service"
  homepage "https://music.163.com/"

  livecheck do
    url "https://music.163.com/api/mac/package/download/latest?arch=#{arch}&productName=music"
    strategy :json do |json|
      next if json["code"] != 200

      data = json["data"]
      next if data["appVer"].blank? || data["buildVer"].blank?

      "#{data["appVer"]},#{data["buildVer"]}"
    end
  end

  auto_updates true
  depends_on :macos

  app "NeteaseMusic.app"

  zap trash: [
    "~/Library/Application Support/com.netease.163music",
    "~/Library/Caches/com.netease.163music",
    "~/Library/Containers/com.netease.163music",
    "~/Library/Cookies/com.netease.163music.binarycookies",
    "~/Library/HTTPStorages/com.netease.163music",
    "~/Library/Preferences/com.netease.163music.plist",
    "~/Library/Saved Application State/com.netease.163music.savedState",
    "~/Library/WebKit/com.netease.163music",
  ]
end
