cask "neteasemusic" do
  arch arm: "arm64", intel: "x86_64"

  version "3.1.13,3451"
  sha256 arm:   "174dd785bec770ce1451a8bbef56cc2b89bda9df8e9be2ba2d46e4bc893fec84",
         intel: "b5e099d9aec3e3fdcd63c9adef93c478f924d13dc587ebe97152434afb2fc65e"

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
