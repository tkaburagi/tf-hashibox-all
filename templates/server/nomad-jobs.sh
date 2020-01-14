#!/usr/bin/env bash
set -e

echo "==> Nomads jobs"

function nomad_run {
  JOBFILE="$1"
  KEY="tmp/nomad/job/$(sha1sum "$JOBFILE" | awk '{print $1}')"
  consul lock tmp/nomad/job-submitting "$(cat <<EOF
if ! consul kv get "$KEY" &> /dev/null; then
  nomad run "$JOBFILE"
  consul kv put "$KEY"
fi
EOF
)"
}

echo "--> Fabio"
sudo tee /tmp/fabio.hcl > /dev/null <<"EOF"
job "fabio" {
  datacenters = ["dc1"]
  type = "system"

  group "fabio" {
    task "fabio" {
      driver = "docker"
      config {
        image = "${fabio_dockerhub_image}"
        network_mode = "host"
      }

      resources {
        cpu    = 200
        memory = 128
        network {
          mbits = 20
          port "lb" {
            static = 9999
          }
          port "ui" {
            static = 9998
          }
        }
      }
    }
  }
}
EOF
nomad_run /tmp/fabio.hcl

echo "==> Nomad jobs submitted!"
