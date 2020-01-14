#!/usr/bin/env bash
set -e

echo "==> User"

echo "--> Creating user"
sudo useradd "${training_username}" \
  --shell /bin/bash \
  --create-home
echo "${training_username}:${training_password}" | sudo chpasswd
sudo tee "/etc/sudoers.d/${training_username}" > /dev/null <<"EOF"
%${training_username} ALL=NOPASSWD:ALL
EOF
sudo chmod 0440 "/etc/sudoers.d/${training_username}"
sudo usermod -a -G sudo "${training_username}"
sudo su "${training_username}" \
  -c "ssh-keygen -q -t rsa -N '' -b 4096 -f ~/.ssh/id_rsa -C training@hashicorp.com"
sudo sed -i "/^PasswordAuthentication/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo su "${training_username}" \
  -c 'git config --global color.ui true'
sudo su "${training_username}" \
  -c 'git config --global user.email "training@hashicorp.com"'
sudo su ${training_username} \
  -c 'git config --global user.name "HashiCorp Training"'
sudo su ${training_username} \
  -c 'git config --global credential.helper "cache --timeout=3600"'
sudo su ${training_username} \
  -c 'mkdir -p ~/.cache; touch ~/.cache/motd.legal-displayed; touch ~/.sudo_as_admin_successful'

echo "--> Giving sudoless for Docker"
sudo usermod -aG docker "${training_username}"

echo "--> Configuring MOTD"
sudo rm -rf /etc/update-motd.d/*
sudo tee /etc/update-motd.d/00-hashicorp > /dev/null <<"EOF"
#!/bin/sh

echo "Welcome to HashiCorp official training! We are very excited to"
echo "have you on board for this event. This is your official training"
echo "instance. Almost all commands and operations will happen on this"
echo "workstation."
echo ""
echo "Your official training animal identity is:"
echo ""
echo "    ${identity}"
echo ""
echo "Please do not lose this identity as it will be important in"
echo "completing this training course. Have a great day!"
EOF
sudo chmod +x /etc/update-motd.d/00-hashicorp
sudo run-parts /etc/update-motd.d/ &>/dev/null

echo "--> Adding helper for identity retrieval"
sudo tee /etc/profile.d/identity.sh > /dev/null <<"EOF"
function identity {
  echo "${identity}"
}
EOF

echo "--> Ignoring LastLog"
sudo sed -i'' 's/PrintLastLog\ yes/PrintLastLog\ no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "--> Setting bash prompt"
sudo tee -a "/home/${training_username}/.bashrc" > /dev/null <<"EOF"
export PS1="\u@\h:\w > "
EOF

echo "--> Installing Vim plugin for Terraform"
# Pathogen bundle manager
mkdir -p /home/${training_username}/.vim/autoload /home/${training_username}/.vim/bundle && curl -LSso /home/${training_username}/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
echo "execute pathogen#infect()" >> /home/${training_username}/.vimrc
echo "set tabstop=2" >> /home/${training_username}/.vimrc
echo "set shiftwidth=2" >> /home/${training_username}/.vimrc

# Terraform plugin
cd /home/${training_username}/.vim/bundle && git clone https://github.com/hashivim/vim-terraform.git
# Airline plugin for vim statusbar
git clone https://github.com/vim-airline/vim-airline /home/${training_username}/.vim/bundle/vim-airline
sudo chown -R ${training_username}:${training_username} /home/${training_username}/.vim*

echo "==> User is done!"
