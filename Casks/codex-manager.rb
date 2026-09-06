cask "codex-manager" do
  version "0.6.0"

  on_arm do
    sha256 "405cc5fbd877efc1894a74307dd0ae2296636b270371c83cbd818be00766bf0e"

    url "https://github.com/qxcnm/Codex-Manager/releases/download/v#{version}/CodexManager_#{version}_aarch64.dmg"
  end
  on_intel do
    sha256 "f1b503f510dd4708df867e3e0cdb9e19cb399be39fecb716e1492acb3244ed82"

    url "https://github.com/qxcnm/Codex-Manager/releases/download/v#{version}/CodexManager_#{version}_x64.dmg"
  end

  name "CodexManager"
  desc "Desktop manager for Codex"
  homepage "https://github.com/qxcnm/Codex-Manager"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "CodexManager.app"
end
