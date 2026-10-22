cask "gui-for-singbox" do
  version "1.28.1"

  on_arm do
    sha256 "474bd2b7345f5a3d1675581f6fafab61b04b229c421fc11b232e6a15841195fd"

    url "https://github.com/GUI-for-Cores/GUI.for.SingBox/releases/download/v#{version}/GUI.for.SingBox-darwin-arm64.zip"
  end
  on_intel do
    sha256 "58434bf3950510641a974c0b8b23e2eacb0395f8a67aef2a963c56bf8626c546"

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
