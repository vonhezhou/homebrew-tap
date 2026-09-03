cask "codex-manager" do
  version "0.5.6"

  on_arm do
    sha256 "7e1d8b7122a21e3e58db2f042a5a52dde24280117be9c235518b6094709a400b"

    url "https://github.com/qxcnm/Codex-Manager/releases/download/v#{version}/CodexManager_#{version}_aarch64.dmg"
  end
  on_intel do
    sha256 "2cc2ab83bc95c1759a39669ed712444b8a9b50538e6a9df972a3c842f5b8782b"

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
