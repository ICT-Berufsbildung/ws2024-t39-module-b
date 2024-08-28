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

# Disable delay after incorrect PAM authentication
sed -i '/pam_unix.so/ s/$/ nodelay/g' /etc/pam.d/common-auth

# Install zealdocs
# Install required packages unattended
export DEBIAN_FRONTEND=noninteractive
apt-get -qqy update
apt-get install -qqy \
  -o DPkg::options::="--force-confdef" \
  -o DPkg::options::="--force-confold" \
  zeal
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

su - appadmin -c 'mkdir -p /home/appadmin/.local/share/Zeal/Zeal/docsets'

# Download docsets
wget -nv -O /tmp/Ansible.tgz 'https://kapeli.com/feeds/zzz/versions/Ansible/2.15.5/Ansible.tgz'
su - appadmin -c 'tar -xzf /tmp/Ansible.tgz -C /home/appadmin/.local/share/Zeal/Zeal/docsets'
wget -nv -O /tmp/Python_3.tgz 'https://kapeli.com/feeds/zzz/versions/Python_3/3.9.2/Python_3.tgz'
su - appadmin -c 'tar -xzf /tmp/Python_3.tgz -C /home/appadmin/.local/share/Zeal/Zeal/docsets'

su - appadmin -c 'ansible-galaxy collection install microsoft.ad'
su - appadmin -c 'ansible-galaxy collection install ansible.windows'

# Install VSCode
wget -nv -O /tmp/vscode.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
apt-get install -y /tmp/vscode.deb
su - appadmin -c '/usr/bin/code --install-extension ms-python.python --force'
su - appadmin -c '/usr/bin/code --install-extension redhat.ansible --force'

mkdir -p /opt/ansible
chown -R appadmin:appadmin /opt/ansible

mkdir -p /usr/local/share/wsc2024
cp /tmp/marking.enc /usr/local/share/wsc2024/marking.enc

cat >/usr/local/bin/grading <<'EOF'
#!/bin/bash

# Check grading scripts are there
if [ ! -d /usr/local/share/wsc2024/marking.enc ]; then
    echo "Please enter the passphrase to decrypt the marking scripts"
    if openssl aes-256-cbc -d -a -pbkdf2 -in /usr/local/share/wsc2024/marking.enc -out /tmp/marking_shares.yml; then
        cp /opt/ansible/inventory/group_vars/paris/shares.yaml /opt/ansible/paris_shares.yaml.orig
        cp /tmp/marking_shares.yml /opt/ansible/inventory/group_vars/paris/shares.yaml
    fi
fi
EOF

chmod +x /usr/local/bin/grading

nmcli con mod "Wired connection 1" \
  ipv4.addresses "10.30.0.4/24" \
  ipv4.gateway "10.30.0.1" \
  ipv4.dns "10.10.0.10,10.10.0.11" \
  ipv4.dns-search "paris.local" \
  ipv4.method "manual"