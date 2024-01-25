// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

provider "random" {}

resource "random_integer" "rand_int" {
  max = 200000
  min = 100000
}

module "resource_names" {
  source = "git::https://github.com/nexient-llc/tf-module-resource_name.git?ref=1.0.0"

  for_each = var.resource_names_map

  logical_product_family  = var.product_family
  logical_product_service = var.product_service
  region                  = var.region
  class_env               = var.environment
  cloud_resource_type     = each.value.name
  instance_env            = var.environment_number
  maximum_length          = each.value.max_length
}

module "resource_group" {
  source = "git::https://github.com/nexient-llc/tf-azurerm-module_primitive-resource_group.git?ref=0.2.0"

  name     = module.resource_names["rg"].standard
  location = var.region

  tags = merge(var.tags, { resource_name = module.resource_names["rg"].standard })

}

module "vnet" {
  source = "git@github.com:nexient-llc/tf-azurerm-module_primitive-virtual_network.git?ref=feature/init"

  vnet_location                                         = var.region
  resource_group_name                                   = module.resource_group.name
  vnet_name                                             = module.resource_names["vnet"].standard
  address_space                                         = ["10.0.0.0/16"]
  subnet_names                                          = ["subnet-1", "subnet-2"]
  subnet_prefixes                                       = ["10.0.5.0/24", "10.0.6.0/24"]
  bgp_community                                         = null
  ddos_protection_plan                                  = null
  dns_servers                                           = []
  nsg_ids                                               = {}
  route_tables_ids                                      = {}
  subnet_delegation                                     = {}
  subnet_enforce_private_link_endpoint_network_policies = {}
  subnet_enforce_private_link_service_network_policies  = {}
  subnet_service_endpoints                              = {}
  tracing_tags_enabled                                  = false
  tracing_tags_prefix                                   = ""
  use_for_each                                          = true

  tags = merge(var.tags, { resource_name = module.resource_names["vnet"].standard })

  depends_on = [module.resource_group]
}

module "private_dns_zone" {
  source = "git@github.com:nexient-llc/tf-azurerm-module_primitive-private_dns_zone.git?ref=feature/init"

  resource_group_name = module.resource_group.name
  zone_name           = "example-${random_integer.rand_int.result}.com"

  tags = var.tags

  depends_on = [module.resource_group]
}

module "vnet_link" {
  source = "../.."

  link_name             = module.resource_names["vnet_link"].standard
  private_dns_zone_name = module.private_dns_zone.zone_name
  resource_group_name   = module.resource_group.name
  virtual_network_id    = module.vnet.vnet_id

  tags = var.tags

  depends_on = [module.vnet, module.private_dns_zone]
}
