cask "gui-for-singbox" do
  version "1.27.0"

  on_arm do
    sha256 "47ead32ad2fc0c8418a04b63e41a7fbc56c3489af2cfa5b9251cfb8f08b498db"

    url "https://github.com/GUI-for-Cores/GUI.for.SingBox/releases/download/v#{version}/GUI.for.SingBox-darwin-arm64.zip"
  end
  on_intel do
    sha256 "69678579531b7189e970dba41be5568b32c2e9ec48f02a5eead5c481cef9beee"

    url "https://github.com/GUI-for-Cores/GUI.for.SingBox/releases/download/v#{version}/GUI.for.SingBox-darwin-amd64.zip"
  end

  name "GUI.for.SingBox"
  desc "Graphical user interface for sing-box"
  homepage "https://github.com/GUI-for-Cores/GUI.for.SingBox"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "GUI.for.SingBox.app"
end
