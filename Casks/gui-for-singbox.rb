cask "gui-for-singbox" do
  version "1.29.0"

  on_arm do
    sha256 "c1656182b1ea8014946305ceab3c91f729ee6ca288bef686c97e4e0c558be4c2"

    url "https://github.com/GUI-for-Cores/GUI.for.SingBox/releases/download/v#{version}/GUI.for.SingBox-darwin-arm64.zip"
  end
  on_intel do
    sha256 "614dc6b8a809c1c2ad387d1eabbe00ade9bce70440a138e8b75c8159e5c49add"

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
