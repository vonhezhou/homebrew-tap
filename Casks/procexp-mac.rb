cask "procexp-mac" do
  version "1.0.1"
  sha256 "61ae4717e99f45b8bff0741423b990c26f78506a8f4ab433cc4e8b7b1619048b"

  url "https://github.com/microsoft/Procexp-Mac/releases/download/#{version}/ProcExp-#{version}.dmg"
  name "Sysinternals Process Explorer for Mac"
  desc "Process monitoring and inspection tool"
  homepage "https://github.com/microsoft/Procexp-Mac"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "ProcExp.app"

  uninstall launchctl: "com.sysinternals.procexpmac.helper",
            quit:      "com.sysinternals.procexpmac"

  zap trash: [
    "~/Library/Preferences/com.sysinternals.procexpmac.plist",
    "~/Library/Saved Application State/com.sysinternals.procexpmac.savedState",
  ]
end
