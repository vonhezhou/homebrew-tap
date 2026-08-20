cask "gui-for-singbox" do
  version "1.26.1"

  on_arm do
    sha256 "7936eccdff28316599370ab0bf174516a6cde1ecda936e52b6e1adcaac0d4a52"

    url "https://github.com/GUI-for-Cores/GUI.for.SingBox/releases/download/v#{version}/GUI.for.SingBox-darwin-arm64.zip"
  end
  on_intel do
    sha256 "5a489b243c1259a047ce6e7d6d483a7c250cb84b696db2a69ee7c95d0d854b07"

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
