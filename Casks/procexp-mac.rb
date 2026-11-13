cask "procexp-mac" do
  version "1.0.0"
  sha256 "5b45c7825018f4057ee367b0510ea16692f908f10fc406dacd8df4f9ea105aa3"

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
