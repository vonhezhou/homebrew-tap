cask "codex-manager" do
  version "0.5.5"

  on_arm do
    sha256 "45a73efa84902aff90528894715e12702668981d7a2d45732d12b3487a33fbd9"

    url "https://github.com/qxcnm/Codex-Manager/releases/download/v#{version}/CodexManager_#{version}_aarch64.dmg"
  end
  on_intel do
    sha256 "71f51aed0594477c76f3747831af6469783759f8bda4d2f29aae7698dce45fae"

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
