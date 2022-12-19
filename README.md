# Podman installation and configurations
<img width="827" alt="podman" src="https://user-images.githubusercontent.com/97512751/208331173-e78cc588-da1e-428e-8d28-ebedaba15f1a.png">
Docker uses a client-server architecture. Daemon runs behind the scenes where docker-cli provides instructions to docker engine. 

Podman uses a single process architecture, due to this pods, images are smaller in size, it can avoid security issues due to multi-process architecture such as sharing PID namespaces with other containers, privilege escalation(docker uses root privileges behind the scenes) attacks and limited user provisioning with related to well-known ports or even ports in general. 

A rootless container with inside and outside normal users makes the system one of the best to opt from. Podman provides such a great feature. By this the defence will be quite high against attackers.
#### Similarity with Docker:
Commands from docker is as par with commands which is using in docker. This makes the Podman an excellent choice of docker replacement. 

## Objectives
Objective of this process is to install podman and podman-compose. This will also describe how to make a service running even after reboot.
Rootless container run.

## Prerequisites 
- Rhel 8.x /CentOS 8.x /Rocky 8.x /Alma 8.x version with active SELinux and Firewalld running.
- A normal user with “sudo” permission. (Can remove the user from the ‘sudoers’).
- Need to open certain ports as per requirements of container exposed ports.
- Access to internet seemless. (Can remove after the installation).
- Firewall permission to be enabled. 

## Installation
### Prepare with installation file and execute - This will install podman and podman-compose executables.
Create a file “install.sh”, with following contents. 

```
$vi install.sh
```
Copy all contents to the file
```
#!/bin/bash
sudo dnf install -y epel-release
sudo dnf install -y podman podman-docker podman-compose buildah
#Solution for cgroupfs
mkdir ${HOME}/.config/containers/ -p
cat <<EOL>> ${HOME}/.config/containers/containers.conf
[engine]
events_logger = "file"
cgroup_manager = "cgroupfs"
EOL
#Initiate with the simple command to generate .local
podman ps
#SE context fix access of storage
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
```

make the file executable.
```
$chmod +x install.sh
```

Start installation as normal user with sudo privilleges.
```
$sh install.sh
```

Sample output.
```
$ sh install.sh

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for ck:
Last metadata expiration check: 0:39:53 ago on Sun 18 Dec 2022 11:35:38 AM EST.
Dependencies resolved.
==============================================================================================================================
 Package                          Architecture               Version                         Repository                  Size
==============================================================================================================================
Installing:
 epel-release                     noarch                     8-18.el8                        extras                      24 k

Transaction Summary


.
.
.
.
.
.
.


Created symlink /etc/systemd/system/local-fs.target.wants/tmp.mount → /usr/lib/systemd/system/tmp.mount.
● rocky8
    State: running
     Jobs: 0 queued
   Failed: 0 units
    Since: Sun 2022-12-18 12:17:12 EST; 293ms ago
   CGroup: /user.slice/user-1000.slice/user@1000.service
           └─init.scope
             ├─4518 /usr/lib/systemd/systemd --user
             └─4522 (sd-pam)

```
### Sample nginx run

```
podman run -itd -p 8080:80 --name webserver nginx
Resolving "nginx" using unqualified-search registries (/etc/containers/registries.conf)
Trying to pull docker.io/library/nginx:latest...
Getting image source signatures
Copying blob f12443e5c9f7 done
Copying blob ec0f5d052824 done
Copying blob 025c56f98b67 done
Copying blob defc9ba04d7c done
Copying blob 885556963dad done
Copying blob cc9fb8360807 done
Copying config 3964ce7b84 done
Writing manifest to image destination
Storing signatures
926f8a64858e1b757139720f766ee13519da41b799b98d538f07eed159857f6f
```

### Enable service at boot as a normal user.

Make sure the container is running,
```
$ podman ps
CONTAINER ID  IMAGE                           COMMAND               CREATED         STATUS             PORTS                 NAMES
926f8a64858e  docker.io/library/nginx:latest  nginx -g daemon o...  21 seconds ago  Up 21 seconds ago  0.0.0.0:8080->80/tcp  webserver
```

Generate service file
```
$ podman generate systemd --new webserver -f
/home/ck/container-926f8a64858e1b757139720f766ee13519da41b799b98d538f07eed159857f6f.service
```

Create user service directory.
```
$ mkdir -p .config/systemd/user

Rename the name as per your naming convention and move the service file to the directory.
$mv -v /home/ck/container-926f8a64858e1b757139720f766ee13519da41b799b98d538f07eed159857f6f.service   .config/systemd/user/webserver.service
```
Enable the service on reboot and make it a enabled user service.
```
$source .bashrc
$systemctl --user daemon-reload
$ systemctl enable --user webserver.service
Created symlink /home/ck/.config/systemd/user/default.target.wants/webserver.service → /home/ck/.config/systemd/user/webserver.service.
```
Make a reboot and you can see the service is actively running.

## Post installation
* Service file creation is required when there is a container need to keep it active for all the time. Restart policys also can be used. Except the restart makes it kill and that can be avoided by making it as a service.
* Firewall need to be opened as sudo user or root user. 

Firewalld sample
```
$sudo firewall-cmd --permanent --add-port=8080/tcp
$sudo firewall-cmd --reload
```
