cask "kimi-code" do
  version "1.3.2"

  sha256 "f0bd00a83a8a931a7931dec5348444d87808da5ea31af48bbb9788ddcbac6ffa"

  url "https://code.kimi.com/kimi-code/desktop/binaries/#{version}/KimiCode-#{version}-mac-arm64.dmg"
  name "Kimi Code"
  desc "AI coding agent desktop client"
  homepage "https://www.kimi.com/code"

  livecheck do
    url "https://code.kimi.com/kimi-code/desktop/latest-mac.yml"
    strategy :electron_builder
  end

  auto_updates true

  depends_on arch: :arm64
  depends_on macos: :monterey

  app "Kimi Code.app"

  zap trash: [
    "~/Library/Application Support/kimi-code-app",
    "~/Library/Caches/com.kimi.code.desktop",
    "~/Library/Caches/kimi-code-app",
    "~/Library/Preferences/com.kimi.code.desktop.plist",
    "~/Library/Saved Application State/com.kimi.code.desktop.savedState",
  ]
end
