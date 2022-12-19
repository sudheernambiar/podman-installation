#!/bin/bash
#Install needed packages
sudo dnf install -y epel-release
sudo dnf install -y podman podman-docker podman-compose buildah

#Solution for cgroupfs issues
mkdir ${HOME}/.config/containers/ -p
cat <<EOL>> ${HOME}/.config/containers/containers.conf
[engine]
events_logger = "file"
cgroup_manager = "cgroupfs"
EOL

#Initiate with the simple command to generate .local
podman ps

#SE context fix access of storage(rootless runtime)
sudo semanage fcontext -a -e /var/lib/containers $HOME/.local/share/containers
sudo restorecon -R -v $HOME/.local/share/containers

#Enable the docker.io as default image register(You can remove and add your private container registry as well)
sudo sed -e '/unqualified-search-registries/s/^/#/g' -i /etc/containers/registries.conf
sudo sed -i '21i unqualified-search-registries = ["docker.io"]'  /etc/containers/registries.conf

#Restart and enable the podman service
sudo systemctl enable podman
sudo systemctl restart podman

#Issues in reboot and service normalcy with fixing temp mount service enable.
sudo systemctl enable tmp.mount
sudo systemctl start tmp.mount

#Enable user lingering – for running normal user even after user logout.
sudo loginctl enable-linger $USER
sudo podman system renumber

#Crearing environment for rootless containers make as user defined services.
echo "export XDG_RUNTIME_DIR=/run/user/`id -u`" >> ~/.bashrc
source ~/.bashrc
systemctl --user daemon-reload
systemctl --user status
