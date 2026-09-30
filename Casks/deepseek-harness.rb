cask "deepseek-harness" do
  arch arm: "arm64", intel: "x64"

  version "0.2.0-rc.2"
  sha256 arm:   "b83daf23e482d96c4c039a2a786daf3a7082e867ea4ad93c51468020defa8a2a",
         intel: "2c5a0e6a6bb977347f090d58faac0f6caa086bd84e3a9e8b7c1f57afa1698afe"

  url "https://download.deepseek.com/dsh-desk/bin/mac-#{arch}/deepseek-harness-#{version}-mac-#{arch}.zip"
  name "DeepSeek Harness"
  desc "AI agent desktop application with a plugin-based architecture"
  homepage "https://www.deepseek.com/harness/"

  livecheck do
    url "https://download.deepseek.com/dsh-desk/feeds/mac-#{arch}/nightly-mac.yml"
    strategy :electron_builder
  end

  auto_updates true
  depends_on macos: :ventura

  app "DeepSeek Harness.app"
end
