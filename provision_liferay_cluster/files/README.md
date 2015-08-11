This folder is intentionally left blank.
A Liferay bundle(s) to be installed should be placed here. By default the `liferay` role is configured to look for file named `liferay-portal-tomcat-6.2-ce-ga4.zip`. If your file name is different please update it in [all.yml](../group_vars/all.yml) file:

    liferay_archive: 
      local: files/<ANOTHER_FILE_NAME_HERE>.zip

Alternatively you can provide a URL to download the file from: 

    liferay_archive: 
      local: files/liferay-portal-tomcat-6.2-ce-ga4.zip
      url: "http://sourceforge.net/projects/lportal/files/Liferay%20Portal/6.2.3%20GA4/liferay-portal-tomcat-6.2-ce-ga4-20150416163831865.zip"