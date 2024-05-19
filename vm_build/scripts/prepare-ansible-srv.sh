#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

# Install zealdocs
wget -nv -O /tmp/zeal.deb http://deb.debian.org/debian/pool/main/z/zeal/zeal_0.6.1-1.2~bpo11+1_amd64.deb
apt-get install -y /tmp/zeal.deb
# Create Desktop Shortcut for Zealdocs
mkdir -p /home/root/.local/share/applications
cat >/home/root/.local/share/applications/Zeal.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Zeal Docs
Icon=/usr/share/icons/hicolor/32x32/apps/zeal.png
Exec=/usr/bin/zeal
Comment=Offline Documentation Browser
Categories=Development;
Terminal=false
EOF

mkdir -p /home/root/.local/share/Zeal/Zeal/docsets

# Download docsets
wget -nv -O /tmp/Ansible.tgz 'https://kapeli.com/feeds/zzz/versions/Ansible/2.16.6/Ansible.tgz'
tar -xzf /tmp/Ansible.tgz -C /home/root/.local/share/Zeal/Zeal/docsets
wget -nv -O /tmp/Python_3.tgz 'https://kapeli.com/feeds/zzz/versions/Python_3/3.9.2/Python_3.tgz'
tar -xzf /tmp/Python_3.tgz -C /home/root/.local/share/Zeal/Zeal/docsets

ansible-galaxy collection install microsoft.ad
ansible-galaxy collection install ansible.windows

# Install VSCode
wget -nv -O /tmp/vscode.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
apt-get install -y /tmp/vscode.deb
/usr/bin/code --no-sandbox --user-data-dir="~/.vscode-root" --install-extension ms-vscode-remote.remote-ssh --force
/usr/bin/code --no-sandbox --user-data-dir="~/.vscode-root" --install-extension ms-python.python --force
/usr/bin/code --no-sandbox --user-data-dir="~/.vscode-root" --install-extension redhat.ansible --force