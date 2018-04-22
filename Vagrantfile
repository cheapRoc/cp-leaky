# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.hostname = "cp-leaky"
  config.vm.box_check_update = false
  config.vm.network "private_network", ip: "172.16.30.5"
  config.vm.synced_folder ".", "/vagrant"

  config.vm.provider "virtualbox" do |vb|
    console_log = File.join(Dir.tmpdir, "ubuntu-xenial-16.04-cloudimg-console.log")

    vb.gui = false
    vb.memory = 4096
    vb.customize ["modifyvm", :id, "--uartmode1", "file", console_log]
  end

  config.vm.provision "shell", inline: <<-SHELL
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-cache policy docker-ce
    apt-get install -y docker-ce jq
    usermod -aG docker vagrant
    docker run hello-world
  SHELL
end
