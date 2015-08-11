Liferay Infrastructure As Code DEMO
=========

This project demonstrates how to automate Liferay cluster deployments.  


Set up a Liferay cluster on existing infrastructure
------------

### TL;DR

  * go to `fake_production` and run `vagrant up`
  * download `Liferay 6.2 CE GA4` [tomcat bundle](http://sourceforge.net/projects/lportal/files/Liferay%20Portal/6.2.3%20GA4/liferay-portal-tomcat-6.2-ce-ga4-20150416163831865.zip) and save it in `files/liferay-portal-tomcat-6.2-ce-ga4.zip`  
  * go to `provision_liferay_cluster`
  * run `ansible-galaxy install -r requirements.yml`
  * wait for Vagrant (from the first step above) to start all virtual servers (db, app1, app2, web) 
  * run `ansible-playbook site.yml` (it make take a long while to complete)
  * run `ansible liferay -m service -a "name=liferay state=started" --sudo --limit 192.168.21.102` to start a single Liferay instance
  * make sure Liferay is up and running on `192.168.21.102:8080`
  * run `ansible liferay -m service -a "name=liferay state=started" --sudo` to start all Liferay nodes   

### Make sure the infrastructure is in place

Before we start we need to make sure there are actual servers where all the peaces will be installed.
If you have existing servers you wish to use, make sure 

  * you have at least 4 servers available (1 for DB, 2 for Liferay and 1 for Apache load balancer) 
  * they all run some Debian based Linux (Debian, Ubuntu, Mint, ...)
  * Multicast is enabled between all of them 
  * servers have Internet access (for installing OS packages) 
  * there are no firewall rules that will block multicast, nfs, ...
  * you can `ssh` to each and every one of them and the user you use can run commands with `sudo` 

If you don't have servers to experiment with, you can use the provided `fake_production` virtual infrastructure. It is [Vagrant](https://www.vagrantup.com/) based and starts 4 virtual machines (as described above). Make sure you have [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/) installed on a machine with enough memory (8GB at least) and free disk space. Go to `fake_production` folder and run `vagrant up`. Give it some time to start!

### Install Ansible and required roles

You can provision the infrastructure from any machine that is able to connect to your servers (physical or virtual) via `ssh`. In order to do that, this demo uses [Ansible](http://www.ansible.com/home). You don't have to be an expert in Ansible but knowing how it works certainly helps. So   
  
  * make sure you have Ansible installed, can run playbooks and install roles from Galaxy/GitHub ! 
  * then go to `provision_liferay_cluster` folder. 
 
The examples in this project use some publicly available roles from [Ansible Galaxy](http://galaxy.ansible.com/). Those are defined in [provision_liferay_cluster/requirements.yml](provision_liferay_cluster/requirements.yml) file. We need to install them:

```
ansible-galaxy install -r requirements.yml 
``` 
Depending on how you have installed and configured Ansible you may have to use `sudo` to install the roles in Ansible's global roles location. 


### Describe your infrastructure

If you are using the `fake_production` set up, there is nothing to do. The infrastructure is already defined in [provision_liferay_cluster/fake_production.inventory](provision_liferay_cluster/fake_production.inventory) file!  

The inventory file defines several inventory groups: 

  * nfs_server - one machine to install NFS server to
  * nfs_client - machines to install NFS client to
  * mysql - one machine to install MySQL server to
  * java - machines to install Java to
  * liferay - machines to install Liferay to
  * apache - machines to install Apache HTTPD to

Those groups are important as the playbook will use them to figure out where to install what. If you use your own infrastructure you will have to make some changes to provide the IP addresses and credentials for your servers. In this case play attention to `nfs_subnet` variable which specifies what subnet should be used by NFS for sharing folders over the network!

### Provide or download Liferay bundle

By default the `liferay` role is configured to look for file named `liferay-portal-tomcat-6.2-ce-ga4.zip` in the `files` folder. If you have downloaded it already, simply place it there. If your file name is different please update the variable in [provision_liferay_cluster/group_vars/all.yml](provision_liferay_cluster/group_vars/all.yml) file:

    liferay_archive: 
      local: files/<ANOTHER_FILE_NAME_HERE>.zip

Alternatively you can provide a URL to download the file from: 

    liferay_archive: 
      local: files/liferay-portal-tomcat-6.2-ce-ga4.zip
      url: "http://sourceforge.net/projects/lportal/files/Liferay%20Portal/6.2.3%20GA4/liferay-portal-tomcat-6.2-ce-ga4-20150416163831865.zip" 

You can configure this role to install any recent Liferay CE or EE version!    

### Install the cluster

While in `provision_liferay_cluster` folder run

```
ansible-playbook site.ymel
```

It may take a long time to complete. Each server will download and install required software from appropriate software repositories independently. 


### Start Liferay

Since Lifeay 

 * takes a while to start
 * needs to populate it's database on first start
 
the provisioning process does not start it automatically. After successful provisioning run 

```
ansible liferay -m service -a "name=liferay state=started" --sudo --limit 192.168.21.102
```

This tells Ansible to run `liferay` service on server `192.168.21.102` (it doesn't matter which server is specified as long as it is in `liferay` inventory group). The output should be:

``` 
192.168.21.102 | success >> {
    "changed": true, 
    "name": "liferay", 
    "state": "started"
}
```

Wait for Liferay to populate and verify the database. Once you can access it on `http://192.168.21.102:8080` you can start all the other instances:

```
ansible liferay -m service -a "name=liferay state=started" --sudo 
192.168.21.102 | success >> {
    "changed": false, 
    "name": "liferay", 
    "state": "started"
}

192.168.21.103 | success >> {
    "changed": true, 
    "name": "liferay", 
    "state": "started"
}
```

### Learn more

The steps above describe how to install Liferay Cluster based on simple default configuration. However many things (such a shared file system, databases, load balancer) can be configured differently. To do so you need to understand [how the playbook and variables work](playbook_and_variables.md)

 
   
