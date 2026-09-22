cask "kimi-code" do
  version "1.0.2"

  on_arm do
    sha256 "868e9e419508fbc8c0d0744aac3cb7ce06bde028546b64c9444dc992c753435e"

    url "https://code.kimi.com/kimi-code/desktop/binaries/#{version}/KimiCode-#{version}-mac-arm64.dmg"
  end
  on_intel do
    sha256 "6c380e63a9c91921171a20385653778c937de5e0de2509f883959c41319c6560"

    url "https://code.kimi.com/kimi-code/desktop/binaries/#{version}/KimiCode-#{version}-mac-x64.dmg"
  end

  name "Kimi Code"
  desc "AI coding agent desktop client"
  homepage "https://www.kimi.com/code"

  livecheck do
    url "https://code.kimi.com/kimi-code/desktop/latest-mac.yml"
    strategy :electron_builder
  end

  auto_updates true

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
