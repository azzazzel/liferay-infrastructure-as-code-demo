Understanding the playbook and variables
==========

The playbook that installs the whole cluster is [provision_liferay_cluster/site.yml](provision_liferay_cluster/site.yml). Here is what it does (step by step):


Update all OS repos
---------

The first thing is to ask all servers to update their application repositories. 

	- hosts: all
	  tasks:
	  - apt: update_cache=yes
	    sudo: yes  


Install and start NFS server
---------

Next the NFS server will be installed on the hosts defined in `nfs_server` inventory group. You would typically want to have just one server in that group. For `fake_production` it is the same server that runs the database. To install it we use a publicly available role called `atsaki.nfs` (see [here](https://github.com/atsaki/ansible-nfs) for details). 

	- hosts: nfs_server
	  roles:
	  - role: atsaki.nfs
	    sudo: yes   

This role allows configuration trough variables which is done in [all.yml](provision_liferay_cluster/group_vars/all.yml) file:

	nfs_server: "{{ groups.nfs_server[0] }}"

	nfs_exported_directories:
	  - path: /export/Liferay/misc
	    hosts:
	      - name: "{{ nfs_subnet }}"
	        options: ["rw", "sync", "fsid=0", "crossmnt", "no_subtree_check"]
	    mount_point: /mnt/shared/liferay/misc

	  - path: /export/Liferay/document_library
	    hosts:
 	     - name: "{{ nfs_subnet }}"
 	       options: ["rw", "sync", "fsid=0", "crossmnt", "no_subtree_check"]
	    mount_point: /mnt/shared/liferay/document_library

This tells Ansible to 
  * install the NFS server on the first server in the `nfs_server` inventory group.
  * export 2 folders `/export/Liferay/misc` and `/export/Liferay/document_library`
  * the folders will be mounted on `/mnt/shared/liferay/misc` and `/mnt/shared/liferay/document_library`respectively on the NFC clients 


Install NFS client and mount shared folders
---------

Next we want to make sure NFS client is installed and shared folders are mounted on all Liferay servers (actually all servers in `nfs_client` inventory group). The following tasks do exactly this:

	- hosts: nfs_client
	  tasks:inventory group.
	  - name: Install NFS common
	    sudo: yes
	    apt: name={{ item }} state=installed update_cache=yes
	    with_items:
	     - nfs-common
	  - name: Make sure mount points exists
	    sudo: yes
	    file: path={{ item.mount_point }} state=directory mode=0777
	    with_items: nfs_exported_directories
	  - name: Update fstab files
	    sudo: yes
	    lineinfile: 
	     dest: /etc/fstab
	     line: "{{ nfs_server }}:/{{ item.path }}   {{ item.mount_point }}   nfs    auto  0  0"
	    with_items: nfs_exported_directories
	    notify: 
	     - mount nfs
	  handlers:
	  - name: mount nfs
	    sudo: yes
	    shell: mount {{ item.mount_point }}
	    with_items: nfs_exported_directories


Install and start MySQL server + create defined databases
---------

Liferay can work with many different database servers. However for this demo we'll use MySQL. The Ansible role for installing the server and creating default Liferay database is `milendyankov.liferay-db-mysql` ((see [here](https://github.com/milendyankov/ansible-liferay-db-mysql) for details)). Although the role allows for customizations, we use the defaults:

	- hosts: mysql
	  roles:
	  - role: milendyankov.liferay-db-mysql

which installs MySQL server and creates database named `liferay` accessed by user `liferay` with password `liferay`. 

Creation of different/additional databases or users, is possible through providing some additional configuration in [all.yml](provision_liferay_cluster/group_vars/all.yml) file. Here is an example:

    mysql_databases:
     - {name: "<YOUR_DB_NAME>", encoding: "utf8", collation: "utf8_general_ci"}
     - {name: "<ANOTHER_DB_NAME>", encoding: "utf8", collation: "utf8_general_ci"}
     - ...
    mysql_users:
     - {name: "<YOUR_DB_USER>", host: "%", password: "<YOUR_USER_PASSWOORD>", priv: "<YOUR_DB_NAME>.*:ALL"}
     - {name: "<ANOTHER_DB_USER>", host: "%", password: "<ANOTHER_USER_PASSWOORD>", priv: "<ANOTHER_DB_NAME>.*:ALL"}
     -



Install Java
---------

Before we can run Liferay we need Java SDK to be installed on the servers. Publicly available Ansible role called `ANXS.oracle-jdk` (see [here](https://github.com/ANXS/oracle-jdk) for details) is the one we use here to automate the installation. The following code installs latest release of Oracle Java 7:  

	- hosts: java
	  sudo: yes
	  roles:
	  - role: ANXS.oracle-jdk
	    oracle_jdk_java_versions: [7]
	    oracle_jdk_java_version_default: 7


Install (but not start) Liferay as system service
---------

Having Java in place we can now install Liferay using publicly available role called `milendyankov.liferay` (see [here](https://github.com/milendyankov/ansible-liferay) for details).
The default configuration:

	- hosts: liferay
	  roles:
	    - role: milendyankov.liferay

looks for Liferay bundle stored in a file named `liferay-portal-tomcat-6.2-ce-ga4.zip`. It then copies it and extracts it on all servers in `liferay` inventory group. If you what to use a Liferay bundle with different file name (must be packed as ZIP) please update the name/location in [all.yml](provision_liferay_cluster/group_vars/all.yml) file. Alternatively you can provide a URL to download the file from (downloaded only if the local file does not exists). 

Furthermore you can configure Liferay to use different main database, add additional databases, set DL folder, ...
Here is an example of configuration that can be provided in [all.yml](provision_liferay_cluster/group_vars/all.yml) file

      liferay_archive: 
        local: <PATH_TO_STORE_FILE>
        url: "<DOWNLOAD_URL>" 
      liferay_default_database: 
        driver: "com.mysql.jdbc.Driver"
        url: "jdbc:mysql://<DATABASE_SERVER>/<DATABASE_NAME>?useUnicode=true&characterEncoding=UTF-8&useFastDateParsing=false"
        user: "<DATABASE_USER>"
        pass: "<DATABASE_PASSWORD>"
      liferay_dl_folder: "/svr/shared/document_library/"
      liferay_cluster_autodetect: <DATABASE_SERVER>:<DATABASE_PORT>
      liferay_additional_databases:
        - id: custom1
          driver: "com.mysql.jdbc.Driver"
          url: "jdbc:mysql://<DATABASE_SERVER>/<DATABASE_NAME>"
          user: "<DATABASE_USER>"
          pass: "<DATABASE_PASSWORD>"
        - id: custom2
          driver: "oracle.jdbc.OracleDriver",
          url: "jdbc:oracle:thin:@//HOSTNAME:PORT/SERVICENAME"
          user: "<DATABASE_USER>"
          pass: "<DATABASE_PASSWORD>"

The role will also create and register system service for Liferay so it will be automatically started when the server  is (re)started.   


Install and start Apache HTTPD load balancer
---------    

Finally we install Apache HTTPD as load balancer. To do so we use a publicly available role called `milendyankov.liferay-balancer-apache` (see [here](https://github.com/milendyankov/ansible-liferay-balancer-apache) for details). The default configuration:


	- hosts: apache
	  roles:
	    - role: milendyankov.liferay-balancer-apache
    
will 
 
 * make sure Apache 2 is installed
 * enable required Apache modules
 * configure AJP cluster to proxy calls to all servers in `liferay` inventory group
 
 