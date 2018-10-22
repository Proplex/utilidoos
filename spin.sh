bosh-lite() {
    WORKSPACE="$HOME/boshspace"
    ENV_NAME="proto-lite"

    case ${1} in
    (init)
      if [[ ${2} = "--force" ]]; then
        vm_id="$(cat $WORKSPACE/state/state.json | jq --raw-output '.current_vm_cid')"
        stemcell_ids="$(cat $WORKSPACE/state/state.json | jq --raw-output '.stemcells[].cid')"
        echo $vm_id
        for row in $stemcell_ids; do
          VBoxManage controlvm $row poweroff
          VBoxManage unregistervm $row --delete
        done
        VBoxManage controlvm $vm_id poweroff
        VBoxManage unregistervm $vm_id --delete
        rm -rf $WORKSPACE/{state,bosh-deployment}
      fi

      if [[ ${2} = "--flush" ]]; then
        vm_id="$(cat $WORKSPACE/state/state.json | jq '.current_vm_cid')"
        stemcell_ids="$(cat $WORKSPACE/state/state.json | jq '.stemcells[].cid')"
        for row in $stemcell_ids; do
          VBoxManage controlvm $row poweroff
          VBoxManage unregistervm $row --delete
        done
        VBoxManage controlvm $vm_id poweroff
        VBoxManage unregistervm $vm_id --delete
        rm -rf $WORKSPACE
      fi

      if [[ ! -e $WORKSPACE/state ]]; then
        mkdir -p $WORKSPACE/{state,stemcells}
        git clone https://github.com/cloudfoundry/bosh-deployment $WORKSPACE/bosh-deployment
        wget https://raw.githubusercontent.com/Proplex/ezpz-bosh-lite/master/bosh-lite-cloud-config.yml -O $WORKSPACE/bosh-deployment/warden/bosh-lite-cloud-config.yml
#        if [[ ! -f $WORKSPACE/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent.tgz ]]; then
#          wget --content-disposition https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent -O $WORKSPACE/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent.tgz
#        fi
      else
          echo "$WORKSPACE has already been setup, use \`--force\` to nuke the existing environment and re-init." 1>&2
          return 1
      fi
      1 = "deploy"
      return 0
      ;;

    (deploy)
      if [[ ! -e $WORKSPACE ]]; then
        echo "EZPZ has not been initialized. Run \`init\` first." 1>&2
        return 1
      fi
      bosh create-env $WORKSPACE/bosh-deployment/bosh.yml \
        --state $WORKSPACE/state/state.json \
        -o $WORKSPACE/bosh-deployment/virtualbox/cpi.yml \
        -o $WORKSPACE/bosh-deployment/virtualbox/outbound-network.yml \
        -o $WORKSPACE/bosh-deployment/bosh-lite.yml \
        -o $WORKSPACE/bosh-deployment/bosh-lite-runc.yml \
        -o $WORKSPACE/bosh-deployment/jumpbox-user.yml \
        --vars-store $WORKSPACE/state/creds.yml \
        -v director_name="Bosh Lite Director" \
        -v internal_ip=192.168.50.6 \
        -v internal_gw=192.168.50.1 \
        -v internal_cidr=192.168.50.0/24 \
        -v outbound_network_name=NatNetwork
      bosh alias-env $ENV_NAME -e 192.168.50.6 --ca-cert <(bosh int $WORKSPACE/state/creds.yml --path /director_ssl/ca)
      export BOSH_CLIENT=admin
      export BOSH_CLIENT_SECRET=`bosh int $WORKSPACE/state/creds.yml --path /admin_password`
      bosh -e $ENV_NAME update-cloud-config $WORKSPACE/bosh-deployment/warden/bosh-lite-cloud-config.yml
      bosh -e $ENV_NAME upload-stemcell https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3468.30-warden-boshlite-ubuntu-trusty-go_agent.tgz
      echo "We'll need your sudo password to setup the VirtualBox NAT."
      sudo route add -net 10.244.0.0/16     192.168.50.6
      echo "Done, a bosh-lite is spun up for you. To set your login environment vars, use \`login\`"
      echo "BOSH Environment Name: $ENV_NAME"
      echo "BOSH Director IP: 192.168.50.6"
      unset BOSH_CLIENT BOSH_CLIENT_SECRET
      return 0
      ;;

    (login)
      if [[ ! -e $WORKSPACE ]]; then
        echo "EZPZ has not been initialized. Run \`init\` first." 1>&2
        return 1
      fi
      export BOSH_CLIENT=admin
      export BOSH_CLIENT_SECRET=`bosh int $WORKSPACE/state/creds.yml --path /admin_password`
      bosh -e $ENV_NAME login
      return 0
      ;;

    (*)
      echo "Not a valid command. Try \`init\`" 1>&2
      return 1
      ;;


    esac
}
