cask "quiver-launcher" do
  arch arm: "arm64", intel: "x64"

  version "3.5.1"
  sha256 arm:   "be091cb526402333605a0b19da7daf23dd397a7e58eb5a073cd75e35c49acd35",
         intel: "3feafb7e54a92044ccc6dab3a7e9bfc158393fae555f297447741f4975959509"

  url "https://github.com/tgeorgiadis/quiver-launcher/releases/download/v#{version}/QuiverLauncher-osx-#{arch}-Portable.zip"
  name "Quiver Launcher"
  desc "Launcher for downloading, installing, and running apps from GitHub and GitLab"
  homepage "https://github.com/tgeorgiadis/quiver-launcher"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on :macos

  app "QuiverLauncher.app"
end
