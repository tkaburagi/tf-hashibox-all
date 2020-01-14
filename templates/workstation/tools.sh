#!/usr/bin/env bash
set -e

install_from_url "consul-template" "${consul_template_url}"
install_from_url "envconsul" "${envconsul_url}"

install_from_url "sentinel" "${sentinel_url}"
install_from_url "packer" "${packer_url}"

install_from_url "dashboard-service" "${dashboard_service_url}"
install_from_url "counting-service" "${counting_service_url}"
