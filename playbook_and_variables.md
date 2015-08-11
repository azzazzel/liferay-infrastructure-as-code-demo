Understanding the playbook and variables
==========

The playbook that installs the whole cluster is [site.yml](site.yml). It does server things:


Update all OS repos
---------

The fisrst ting is to ask all servers to update their application repositories. 

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

This role allows to define some variables which is done in [all.yml](group_vars/all.yml) file:

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

The following tasks:

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

make sure NFS clients are installed and all shared folders are mounted on all servers in `nfs_client` inventory group.


Install and start MySQL server + create defined databases
---------

This is done by `milendyankov.liferay-db-mysql` ((see [here](https://github.com/milendyankov/ansible-liferay-db-mysql) for details)) :

	- hosts: mysql
	  roles:
	  - role: milendyankov.liferay-db-mysql

Although the role allows for customizations, we use defaults which creates database named `liferay` accessed by user `liferay` with password `liferay`. 

To create different/additional databases or user you can add the following to [all.yml](group_vars/all.yml) file:

    mysql_databases:
     - {name: "lportal", encoding: "utf8", collation: "utf8_general_ci"}
     - {name: "custom", encoding: "utf8", collation: "utf8_general_ci"}
    mysql_users:
     - {name: "user1", host: "%", password: "secret", priv: "lportal.*:ALL"}
     - {name: "user2", host: "%", password: "secret", priv: "custom.*:ALL"}



Install Java
---------

To install Java we use a publicly available role called `ANXS.oracle-jdk` (see [here](https://github.com/ANXS/oracle-jdk) for details).

	- hosts: java
	  sudo: yes
	  roles:
	  - role: ANXS.oracle-jdk
	    oracle_jdk_java_versions: [7]
	    oracle_jdk_java_version_default: 7


Install (but not start) Liferay as system service
---------

To install Liferay we use a publicly available role called `milendyankov.liferay` (see [here](https://github.com/milendyankov/ansible-liferay) for details).
The default configuration:

	- hosts: liferay
	  roles:
	    - role: milendyankov.liferay

looks for Liferay bundle stored in a file named `liferay-portal-tomcat-6.2-ce-ga4.zip`. It then copies it and extracts it on the server. If your file name is different please update it in [all.yml](group_vars/all.yml) file. Alternatively you can provide a URL to download the file from. Furthermore you can configure Liferay to use different main database, add additional databases, set DL folder, ...
Here is an example of configuration one can put in [all.yml](group_vars/all.yml) file

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


Install and start Apache HTTPD load balancer
---------    

To install Apache HTTPD as load balancer we use a publicly available role called `milendyankov.liferay-balancer-apache` (see [here](https://github.com/milendyankov/ansible-liferay-balancer-apache) for details). The default configuration:


	- hosts: apache
	  roles:
	    - role: milendyankov.liferay-balancer-apache
    
will 
 
 * make sure Apache 2 is installed
 * enable required Apache modules
 * configure AJP cluster to proxy calls to all servers in `liferay` inventory group
 
 