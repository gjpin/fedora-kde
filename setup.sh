##### Versions
GOLANG_VERSION=1.17.7
NOMAD_VERSION=1.2.6
CONSUL_VERSION=1.11.3
VAULT_VERSION=1.9.3
TERRAFORM_VERSION=1.1.6

# Set grub2 timeout to 0
sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
sudo grub2-mkconfig -o /etc/grub2.cfg
sudo grub2-mkconfig -o /etc/grub2-efi.cfg

##### FOLDERS
mkdir -p \
${HOME}/.bashrc.d/ \
${HOME}/.local/bin \
${HOME}/src

##### FLATPAK
# Add Flathub and Flathub Beta repos
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update --appstream

# Install Breeze-GTK flatpak theme and allow Flatpaks to access GTK configs
sudo flatpak install -y flathub org.gtk.Gtk3theme.Breeze
sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro

# Install KeePassXC
sudo flatpak install -y flathub org.keepassxc.KeePassXC
sudo flatpak override --unshare=network org.keepassxc.KeePassXC

# Install applications
sudo flatpak install -y flathub com.spotify.Client
sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak install -y flathub org.blender.Blender

# Install Chrome and enable GPU acceleration
sudo flatpak install -y flathub-beta com.google.Chrome
mkdir -p ~/.var/app/com.google.Chrome/config
tee -a ~/.var/app/com.google.Chrome/config/chrome-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--enable-features=UseOzonePlatform
--ozone-platform=wayland
EOF

# Install Chromium and enable GPU acceleration
sudo flatpak install -y flathub org.chromium.Chromium
mkdir -p ~/.var/app/org.chromium.Chromium/config
tee -a ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--enable-features=UseOzonePlatform
--ozone-platform=wayland
EOF

# Install Firefox and enable hardware acceleration
sudo dnf remove -y firefox
sudo flatpak install -y flathub org.mozilla.firefox
sudo flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Open Firefox in headless mode and then close it to create profile folder
timeout 5 flatpak run org.mozilla.firefox --headless

# Import Firefox user settings
cd ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
tee -a user.js << EOF
// Enable hardware acceleration
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.rdd-ffmpeg.enabled", true);
EOF
cd

##### APPLICATIONS
sudo dnf install -y kate htop ansible-core jq

# Git
sudo dnf install -y git-core
git config --global init.defaultBranch main

# Podman
sudo dnf install -y podman
tee -a ${HOME}/.bashrc.d/aliases << EOF
alias docker="podman"
EOF

# SELinux tools and udica
sudo dnf install -y setools-console udica

# Syncthing
sudo dnf install -y syncthing
sudo systemctl enable --now syncthing@${USER}.service

# Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf check-update
sudo dnf install -y code

mkdir -p ${HOME}/.config/Code/User
tee -a ${HOME}/.config/Code/User/settings.json << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": "material-icon-theme",
    "editor.fontWeight": "500",
    "redhat.telemetry.enabled": false,
    "files.associations": {
        "*.j2": "terraform",
        "*.hcl": "terraform",
        "*.bu": "yaml",
        "*.ign": "json"
    },
    "workbench.colorTheme": "GitHub Dark",
    "extensions.ignoreRecommendations": true
}
EOF

code --install-extension PKief.material-icon-theme
code --install-extension golang.Go
code --install-extension HashiCorp.terraform
code --install-extension redhat.ansible
code --install-extension dbaeumer.vscode-eslint
code --install-extension editorconfig.editorconfig
code --install-extension octref.vetur
code --install-extension github.github-vscode-theme

# Enable Wayland for Electron
tee -a ${HOME}/.config/electron-flags.conf << EOF
--enable-features=UseOzonePlatform
--ozone-platform=wayland
EOF

# Hashistack
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o hashistack-nomad.zip
curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o hashistack-consul.zip
curl -sSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o hashistack-vault.zip
curl -sSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o hashistack-terraform.zip
unzip 'hashistack-*.zip' -d  ${HOME}/.local/bin
rm hashistack-*.zip

# Install hey
curl -sSL https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -o ${HOME}/.local/bin/hey
chmod +x ${HOME}/.local/bin/hey

# Golang
wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
rm -rf ${HOME}/.local/go
tar -C ${HOME}/.local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
grep -qxF 'export PATH=$PATH:${HOME}/.local/go/bin' ${HOME}/.bashrc.d/exports || echo 'export PATH=$PATH:${HOME}/.local/go/bin' >> ${HOME}/.bashrc.d/exports
rm go${GOLANG_VERSION}.linux-amd64.tar.gz

# Node.js 16
sudo dnf module install -y nodejs:16/default

##### KDE
# Disable baloo (file indexer)
balooctl suspend
balooctl disable

# Remove media players
sudo dnf remove -y dragon elisa-player juk kamoso

# Remove akonadi
sudo dnf remove -y \*akonadi\*

# Remove games
sudo dnf remove -y kmahjongg kmines kpat

# Remove misc applications
sudo dnf remove -y akregator kruler qt-qdbusviewer qt5-qdbusviewer kget konversation krdc krfb kwrite

# Configure Plasma
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezetwilight.desktop"
kwriteconfig5 --file kdeglobals --group KDE --key SingleClick --type bool true
kwriteconfig5 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"

# Enable 2 desktops
kwriteconfig5 --file kwinrc --group Desktops --key Name_2 "Desktop 2"
kwriteconfig5 --file kwinrc --group Desktops --key Number "2"
kwriteconfig5 --file kwinrc --group Desktops --key Rows "1"

# Change window decorations
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Configure Konsole
kwriteconfig5 --file konsolerc --group KonsoleWindow --key SaveGeometryOnExit --type bool false
kwriteconfig5 --file konsolerc --group KonsoleWindow --key ShowMenuBarByDefault --type bool false
kwriteconfig5 --file konsolerc --group MainWindow --key MenuBar "Disabled"
kwriteconfig5 --file konsolerc --group MainWindow --key StatusBar "Disabled"
kwriteconfig5 --file konsolerc --group MainWindow --key ToolBarsMovable "Disabled"

# Disable screen edges
kwriteconfig5 --file kwinrc --group Effect-PresentWindows --key BorderActivateAll "9"
kwriteconfig5 --file kwinrc --group TabBox --key BorderActivate "9"

# Change Task Switcher behaviour
kwriteconfig5 --file kwinrc --group TabBox --key HighlightWindows  --type bool false
kwriteconfig5 --file kwinrc --group TabBox --key LayoutName "thumbnail_grid"

# Use Scale window animation
kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_fadeEnabled --type bool false
kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_scaleEnabled --type bool true

# Disable splash screen
kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none"
kwriteconfig5 --file ksplashrc --group KSplash --key Theme "none"

# Import Konsole Github color schemes
wget -P $HOME/.local/share/konsole https://raw.githubusercontent.com/gjpin/fedora-kde/main/konsole/dark.colorscheme
wget -P $HOME/.local/share/konsole https://raw.githubusercontent.com/gjpin/fedora-kde/main/konsole/light.colorscheme

# Customize bash
tee -a ~/.bashrc.d/prompt << EOF
PS1="\[\e[1;36m\]\w\[\e[m\] \[\e[1;33m\]\\$\[\e[m\] "

PROMPT_COMMAND="export PROMPT_COMMAND=echo"
EOF

# Disable app launch feedback
kwriteconfig5 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
kwriteconfig5 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false

# Autologin
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key "Relogin" --type bool false
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key "Session" "plasma"
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key "User" "${USER}"

# SDDM theme
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"

# Enable overview
sudo kwriteconfig5 --file kwinrc --group Plugins --key "overviewEnabled" --type bool true
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+Tab,none,Toggle Overview"

# Use KDE Wallet to store ssh key passphrases
mkdir -p ~/.config/autostart/
tee -a ~/.config/autostart/ssh-add.desktop << EOF
[Desktop Entry]
Exec=ssh-add -q /home/$USER/.ssh/id_ed25519
Name=ssh-add
Type=Application
EOF

mkdir -p ~/.config/plasma-workspace/env/
tee -a ~/.config/plasma-workspace/env/askpass.sh << EOF
#!/bin/sh
export SSH_ASKPASS='/usr/bin/ksshaskpass'
EOF

chmod +x ~/.config/plasma-workspace/env/askpass.sh

#SSH_ASKPASS='/usr/bin/ksshaskpass'
#ssh-add ~/.ssh/id_ed25519 </dev/null

##### SHORTCUTS
# Desktop switch
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 1" "none,none,Activate Task Manager Entry 1"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 2" "none,none,Activate Task Manager Entry 2"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 3" "none,none,Activate Task Manager Entry 3"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 4" "none,none,Activate Task Manager Entry 4"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 5" "none,none,Activate Task Manager Entry 5"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 6" "none,none,Activate Task Manager Entry 6"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 7" "none,none,Activate Task Manager Entry 7"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 8" "none,none,Activate Task Manager Entry 8"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 9" "none,none,Activate Task Manager Entry 9"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 10" "none,none,Activate Task Manager Entry 10"

kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 1" "Meta+1,none,Switch to Desktop 1"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 2" "Meta+2,none,Switch to Desktop 2"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 3" "Meta+3,none,Switch to Desktop 3"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 4" "Meta+4,none,Switch to Desktop 4"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 5" "Meta+5,none,Switch to Desktop 5"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 6" "Meta+6,none,Switch to Desktop 6"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 7" "Meta+7,none,Switch to Desktop 7"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 8" "Meta+8,none,Switch to Desktop 8"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 9" "Meta+9,none,Switch to Desktop 9"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"

kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 1" "Meta+\!,none,Window to Desktop 1"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 2" "Meta+@,none,Window to Desktop 2"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 3" "Meta+#,none,Window to Desktop 3"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 4" "Meta+$,none,Window to Desktop 4"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 5" "Meta+%,none,Window to Desktop 5"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 6" "Meta+^,none,Window to Desktop 6"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 7" "Meta+&,none,Window to Desktop 7"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 8" "Meta+*,none,Window to Desktop 8"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 9" "Meta+(,none,Window to Desktop 9"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 10" "Meta+),none,Window to Desktop 10"

# Konsole
kwriteconfig5 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+Return,none,Konsole"

# Close windows
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Shift+Q,none,Close Window"

# Spectacle
kwriteconfig5 --file kglobalshortcutsrc --group "org.kde.spectacle.desktop" --key "RectangularRegionScreenShot" "Meta+Shift+S,none,Capture Rectangular Region"
