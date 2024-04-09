# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

# Configure the Vault Provider by $VAULT_ADDR and $VAULT_TOKEN
provider "vault" {}

data "vault_kv_secret_v2" "auth_secret" {
  mount = "kv"
  name  = "openstack-auth"
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = data.vault_kv_secret_v2.auth_secret.data["username"]
  tenant_id   = data.vault_kv_secret_v2.auth_secret.data["project_id"]
  password    = data.vault_kv_secret_v2.auth_secret.data["password"]
  auth_url    = data.vault_kv_secret_v2.auth_secret.data["auth_url"]
}

# Define security group
resource "openstack_networking_secgroup_v2" "glezova_tg_secgroup" {
  name        = "glezova_tg_secgroup"
  description = "Security group for ssh and http/https"
}

# Security group rule for ssh
resource "openstack_networking_secgroup_rule_v2" "ssh_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.glezova_tg_secgroup.id
}

# Security group rule for http
resource "openstack_networking_secgroup_rule_v2" "http_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.glezova_tg_secgroup.id
}

# Security group rule for https
resource "openstack_networking_secgroup_rule_v2" "https_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.glezova_tg_secgroup.id
}

# Configure an instance
resource "openstack_compute_instance_v2" "glezova_bot" {
  name              = "glezova_bot_tf"
  image_name        = var.image_name
  flavor_name       = var.flavor_name
  key_pair          = var.key_pair
  security_groups   = [openstack_networking_secgroup_v2.glezova_tg_secgroup.name]

  network {
    name = var.network_name
  }
}
