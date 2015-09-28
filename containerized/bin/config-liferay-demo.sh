etcdctl set /liferay/demo/db/driver 'com.mysql.jdbc.Driver'
etcdctl set /liferay/demo/db/url 'jdbc:mysql://192.168.40.100/liferay?useUnicode=true&characterEncoding=UTF-8&useFastDateParsing=false'
etcdctl set /liferay/demo/db/username 'liferay'
etcdctl set /liferay/demo/db/password 'liferay'
etcdctl set /liferay/demo/dl/dir '/var/lib/liferay/data/document_library'
etcdctl set /liferay/demo/clusterlink/autodetect '192.168.40.100:3306'
etcdctl set /liferay/demo/clusterlink/config <<- 'EOF'
	<config xmlns="urn:org:jgroups"
	        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	        xsi:schemaLocation="urn:org:jgroups http://www.jgroups.org/schema/JGroups-3.1.xsd">
	    <TCP 
	         singleton_name="liferay" 
	         bind_port="7800"
	         loopback="false"
	         recv_buf_size="${tcp.recv_buf_size:5M}"
	         send_buf_size="${tcp.send_buf_size:640K}"
	         max_bundle_size="64K"
	         max_bundle_timeout="30"
	         enable_bundling="true"
	         use_send_queues="true"
	         sock_conn_timeout="300"

	         timer_type="old"
	         timer.min_threads="4"
	         timer.max_threads="10"
	         timer.keep_alive_time="3000"
	         timer.queue_max_size="500"
	         
	         thread_pool.enabled="true"
	         thread_pool.min_threads="1"
	         thread_pool.max_threads="10"
	         thread_pool.keep_alive_time="5000"
	         thread_pool.queue_enabled="false"
	         thread_pool.queue_max_size="100"
	         thread_pool.rejection_policy="discard"

	         oob_thread_pool.enabled="true"
	         oob_thread_pool.min_threads="1"
	         oob_thread_pool.max_threads="8"
	         oob_thread_pool.keep_alive_time="5000"
	         oob_thread_pool.queue_enabled="false"
	         oob_thread_pool.queue_max_size="100"
	         oob_thread_pool.rejection_policy="discard"/>
	                         
	<!-- Customization START -->                       
	    <FILE_PING location="${jgroups.fileping.location:/opt/liferay/cluster-config/file_ping}" />
	<!-- Customization END -->

	    <MERGE2  min_interval="10000"
	             max_interval="30000"/>
	    <FD_SOCK/>
	    <FD timeout="3000" max_tries="3" />
	    <VERIFY_SUSPECT timeout="1500"  />
	    <BARRIER />
	    <pbcast.NAKACK2 use_mcast_xmit="false"
	                   discard_delivered_msgs="true"/>
	    <UNICAST />
	    <pbcast.STABLE stability_delay="1000" desired_avg_gossip="50000"
	                   max_bytes="4M"/>
	    <pbcast.GMS print_local_addr="true" join_timeout="3000"

	                view_bundling="true"/>
	    <UFC max_credits="2M"
	         min_threshold="0.4"/>
	    <MFC max_credits="2M"
	         min_threshold="0.4"/>
	    <FRAG2 frag_size="60K"  />
	    <!--RSVP resend_interval="2000" timeout="10000"/-->
	    <pbcast.STATE_TRANSFER/>
	</config>
EOF