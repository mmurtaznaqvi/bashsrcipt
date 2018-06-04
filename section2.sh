#!/bin/sh

while [ 1 ]
do
	UPSTREAM=${1:-'@{u}'}
	LOCAL=$(git rev-parse @)	
	REMOTE=$(git rev-parse "$UPSTREAM")
	BASE=$(git merge-base @ "$UPSTREAM")

	if [ $LOCAL = $REMOTE ]; then
    		echo "Up-to-date"
	elif [ $LOCAL = $BASE ]; then
         
         echo "Step 1. Get Updates"
        git fetch

        echo "Step 2. Clone Openvswitch git Repo"
        git clone https://github.com/openvswitch/ovs.git


		    echo "Step 3.  Build OvS"
		    cd ovs/
		    ./boot.sh
		    ./configure --with-linux=/lib/modules/`uname -r`/build
        make
        
	   	  echo "Step 4. Install OpenVswitch"
		    sudo make install
            
		    echo "Step 5. Create OvS Database"
		    sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema

		    echo "Step 6. Run OvS..."
		    sudo ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
                 --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
                 --private-key=db:Open_vSwitch,SSL,private_key \
                 --certificate=db:Open_vSwitch,SSL,certificate \
                 --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
                 --pidfile --detach
		    sudo ovs-vsctl --no-wait init
		    sudo ovs-vswitchd --pidfile --detach
	
	fi
done

for i in {1..100}
do
  ip=192.168.1.${i}
  portOut=$(( RANDOM % (4 - 1 + 1 ) + 1 ))
  echo $ip
  sudo ovs-ofctl add-flow br1 dl_type=0x0800,nw_dst=$ip,actions=output:$portOut
done



