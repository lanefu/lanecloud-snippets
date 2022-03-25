
job "ubuntu-amd64-lanecloud-cloud" {
  datacenters = ["dc1"]
  type = "batch"

  meta {
    source = "https://cloud-images.ubuntu.com/lanecloud/current/lanecloud-server-cloudimg-amd64.img"
    image = "jammy-server-cloudimg-amd64.img"
    bridge = "lc_br_public0"
    image_size = "80G"
    cloud_init_base_url = "https://example.com/qemu-nocloud"
    smp = "20"
    cloud_init = "vm1"
    domain = "lanecloud.example.com"
    address = "10.255.255.137/26"
    broadcast = "10.255.255.191"
    netmask = "255.255.255.192"
    network = "10.255.255.128"
    gateway = "10.255.255.129"
   
  }

  parameterized {
    payload = "forbidden"
    meta_required = ["name"]
    meta_optional = ["mac", "image_size"]
  }

   constraint {
     attribute = "${attr.kernel.name}"
     value     = "linux"
   }



  group "ubuntu-amd64-lanecloud-dispatch" { 

    task "fetch-volume" {
     lifecycle {
           hook = "prestart"
           sidecar = false
         }

      driver = "docker"

      config {
        image = "debian"
        force_pull = false
        args = [ "/bin/bash", "${NOMAD_TASK_DIR}/entrypoint.sh" ]

       mount {
           type = "bind"
           target = "/archive"
           source = "/mnt/lc/archive"
           readonly = false
           bind_options {
                 propagation = "rshared"
               }
         }
      }
      resources {
        cpu    = 500
        memory = 300
      }

      template {
        data = <<EOH
      mkdir -p ${NOMAD_ALLOC_DIR}/image/
      cp -v /archive/images/${NOMAD_META_IMAGE} ${NOMAD_ALLOC_DIR}/image/${NOMAD_META_IMAGE}
      EOH
      
        destination = "local/entrypoint.sh"
        env         = false
       
      }
    }
    task "provision" {
     lifecycle {
           hook = "prestart"
           sidecar = false
         }

      driver = "docker"

      config {
        image = "debian"
        force_pull = false
        args = [ "/bin/bash", "${NOMAD_TASK_DIR}/entrypoint.sh" ]

      }

      resources {
        cpu    = 500
        memory = 300
      }

      template {
        data = <<EOH
      apt update -y
      apt install -y qemu-utils genisoimage
      mkdir -p ${NOMAD_ALLOC_DIR}/image
      echo "creating null image hack"
      qemu-img create -f qcow2 ${NOMAD_ALLOC_DIR}/image/null.img 1M 
      echo "resizing image to ${NOMAD_META_image_size}"
      qemu-img resize ${NOMAD_ALLOC_DIR}/image/${NOMAD_META_IMAGE} ${NOMAD_META_image_size}
      echo "#include" > local/user-data
      echo "${NOMAD_META_CLOUD_INIT_BASE_URL}/${NOMAD_META_CLOUD_INIT}/user-data" >> local/user-data
      cd local
      echo "create cidata iso"
      echo "dir is $(pwd)"
      genisoimage  -output ${NOMAD_ALLOC_DIR}/image/seed.iso -volid cidata -joliet -rock user-data meta-data network-config
      echo "meta-data"
      cat meta-data
      echo "user-data"
      cat user-data
      EOH
      
        destination = "local/entrypoint.sh"
        env         = false
       
      }
      template {
        data = <<EOH
instance-id: {{ env "NOMAD_ALLOC_ID" }}
local-hostname: {{ env "NOMAD_META_NAME" }}.{{ env "NOMAD_META_DOMAIN" }}
dsmode: net
      EOH
      
        destination = "local/meta-data"
        env         = false
       
      }
      template {
        data = <<EOH
version: 1
config:
  - type: physical
    name: ens4
#    mac_address: "{{ env "NOMAD_META_MAC" }}"
    subnets:
       - type: static
         address: {{ env "NOMAD_META_ADDRESS" }}
         gateway: {{ env "NOMAD_META_GATEWAY" }}
         dns_nameservers:
           - 1.1.1.1
           - 8.8.8.8
         dns_search:
           - lanecloud.example.com
    EOH
    
        destination = "local/network-config"
        env         = false
       
      }

    }

    task "ubuntu-lanecloud-instance" {
      driver = "qemu"
      service {
        name = "${NOMAD_META_NAME}"
        tags = ["ubuntu", "lanecloud", "dispatch"]

        meta {
          fqdn = "${NOMAD_META_NAME}.${NOMAD_META_DOMAIN}"
        }
      }

      config {
        port_map {
          amd64_ssh = 22
        }
        accelerator = "kvm"
        image_path = "../alloc/image/null.img"
        graceful_shutdown = true
        args = ["-smp", "${NOMAD_META_SMP}", "-drive", "file=../alloc/image/${NOMAD_META_IMAGE},id=drive0,if=none", "-device", "virtio-blk-pci,drive=drive0,bootindex=0", "-cdrom", "../alloc/image/seed.iso", "-netdev", "bridge,br=${NOMAD_META_BRIDGE},id=n${NOMAD_ALLOC_ID}", "-device", "virtio-net,netdev=n${NOMAD_ALLOC_ID},mac=${NOMAD_META_MAC}"]
      }



       resources {
         memory = 28000
         network {
           port "amd64_ssh" {}
        }
       }


    } # end task
  } #end group
}
