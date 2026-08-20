cask "codex-manager" do
  version "0.5.3"

  on_arm do
    sha256 "ab86f8af0037fdff873f309c24373547206822c0c813fb3f87c3431178d9fb25"

    url "https://github.com/qxcnm/Codex-Manager/releases/download/v#{version}/CodexManager_#{version}_aarch64.dmg"
  end
  on_intel do
    sha256 "23934a4cbbb70c15189f028c86cb79d4788427f14ec29551b3a2c1d27efbac3b"

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
