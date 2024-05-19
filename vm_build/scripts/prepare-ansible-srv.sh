#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

# Configure sudo
cat >/etc/sudoers <<'EOF'
Defaults env_reset
Defaults mail_badpass
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

root ALL=(ALL:ALL) ALL
%sudo ALL=(ALL:ALL) NOPASSWD: ALL
EOF

# Set hostname
hostnamectl set-hostname ANSIBLE-SRV

# Install zealdocs
wget -nv -O /tmp/zeal.deb http://deb.debian.org/debian/pool/main/z/zeal/zeal_0.6.1-1.2~bpo11+1_amd64.deb
apt-get install -y /tmp/zeal.deb
# Create Desktop Shortcut for Zealdocs
su - appadmin -c 'mkdir -p /home/appadmin/.local/share/applications'
su - appadmin -c 'cat >/home/appadmin/.local/share/applications/Zeal.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Zeal Docs
Icon=/usr/share/icons/hicolor/32x32/apps/zeal.png
Exec=/usr/bin/zeal
Comment=Offline Documentation Browser
Categories=Development;
Terminal=false
EOF'

# Install temporarily zeal-cli
wget -nv -P /tmp https://github.com/Morpheus636/zeal-cli/releases/download/v1.1.0/zeal-cli
chmod +x /tmp/zeal-cli
su - appadmin -c 'mkdir -p /home/appadmin/.local/share/Zeal/Zeal/docsets'

# Download docsets
wget -nv -O /tmp/Ansible.tgz 'https://kapeli.com/feeds/zzz/versions/Ansible/2.16.6/Ansible.tgz'
su - appadmin -c 'tar -xzf /tmp/Ansible.tgz -C /home/appadmin/.local/share/Zeal/Zeal/docsets'
wget -nv -O /tmp/Python_3.tgz 'https://kapeli.com/feeds/zzz/versions/Python_3/3.9.2/Python_3.tgz'
su - appadmin -c 'tar -xzf /tmp/Python_3.tgz -C /home/appadmin/.local/share/Zeal/Zeal/docsets'

su - appadmin -c 'ansible-galaxy collection install microsoft.ad'
su - appadmin -c 'ansible-galaxy collection install ansible.windows'

# Install VSCode
wget -nv -O /tmp/vscode.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
apt-get install -y /tmp/vscode.deb
su - appadmin -c '/usr/bin/code --install-extension ms-vscode-remote.remote-ssh --force'
su - appadmin -c '/usr/bin/code --install-extension ms-python.python --force'
su - appadmin -c '/usr/bin/code --install-extension redhat.ansible --force'

mkdir -p /opt/ansible
chown -R appadmin:appadmin /opt/ansible