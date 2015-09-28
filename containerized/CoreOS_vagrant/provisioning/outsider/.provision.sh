
# -------------------------
# configure NFS
# -------------------------
sudo apt-get install nfs-kernel-server
sudo mkdir -p /export
sudo chown nobody:nogroup /export
sudo chmod 777 /export
sudo sh -c "echo '/export 192.168.0.0/16(rw,sync,fsid=0,crossmnt,no_subtree_check,no_root_squash)' >> /etc/exports"
sudo exportfs -ra
sudo service nfs-kernel-server restart
sudo service rpc-statd restart

# -------------------------
# configure MySQL
# -------------------------
sudo debconf-set-selections <<< 'mysql-server-5.6 mysql-server/root_password password test'
sudo debconf-set-selections <<< 'mysql-server-5.6 mysql-server/root_password_again password test'
sudo apt-get install -y mysql-server-5.6
sudo sh -c "echo '[mysqld] \n bind-address = 0.0.0.0' > /etc/mysql/mysql.conf.d/xxx_bind.cnf"
sudo service mysql restart
mysql -u root -ptest -e "CREATE DATABASE IF NOT EXISTS liferay CHARACTER SET utf8"
mysql -u root -ptest -e "CREATE USER 'liferay'@'%' IDENTIFIED BY 'liferay'"
mysql -u root -ptest -e "GRANT ALL PRIVILEGES ON liferay.* TO 'liferay'@'%' WITH GRANT OPTION"


# -------------------------
# install Docker and start docker registry
# -------------------------
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo mkdir /docker-registry
sudo docker load < /install/containers/registry_2.tar
sudo docker run \
    -d \
    -p 5000:5000 \
    --restart=always \
    --name registry \
    -e SETTINGS_FLAVOR=local \
    -e SEARCH_BACKEND=sqlalchemy \
    -e LOGLEVEL=DEBUG \
    -v /docker-registry:/var/lib/registry \
    registry:2