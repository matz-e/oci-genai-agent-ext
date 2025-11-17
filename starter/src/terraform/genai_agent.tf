# Object Storage
variable "namespace" {
  description = "OCI Object Storage Namespace"
}

# -- Object Storage ---------------------------------------------------------

resource "oci_objectstorage_bucket" "starter_bucket" {
  compartment_id = local.lz_serv_cmp_ocid
  namespace      = var.namespace
  name           = "${var.prefix}-public-bucket"
  access_type    = "ObjectReadWithoutList"
  object_events_enabled = true

  freeform_tags = local.freeform_tags
}

locals {
  bucket_url = "https://objectstorage.${var.region}.oraclecloud.com/n/${var.namespace}/b/${var.prefix}-public-bucket/o"
}  

# -- Agent ------------------------------------------------------------------

resource "oci_generative_ai_agent_agent" "starter_agent" {
  compartment_id                 = local.lz_serv_cmp_ocid
  display_name                   = "${var.prefix}-agent"
  description                    = "${var.prefix}-agent"
  welcome_message                = "How can I help you ?"
  knowledge_base_ids = [
    oci_generative_ai_agent_knowledge_base.starter_agent_kb.id
  ]  
  freeform_tags = local.freeform_tags
}

# -- Agent Endpoint ---------------------------------------------------------

resource "oci_generative_ai_agent_agent_endpoint" "starter_agent_endpoint" {
  compartment_id                 = local.lz_serv_cmp_ocid
  agent_id                       = oci_generative_ai_agent_agent.starter_agent.id
  display_name                  = "${var.prefix}-agent-endpoint"
  description                   = "${var.prefix}-agent-endpoint"
  should_enable_citation        = "true"
  should_enable_session         = "true"
  should_enable_trace           = "true"
  content_moderation_config  {
    should_enable_on_input = "false"
    should_enable_on_output = "false"
  }
  session_config              {
    idle_timeout_in_seconds = 3600
  }
  freeform_tags = local.freeform_tags  
}

# -- StreamLit / NLB ---------------------------------------------------------

resource "oci_network_load_balancer_network_load_balancer" "starter_nlb" {
  compartment_id = local.lz_app_cmp_ocid
  subnet_id = data.oci_core_subnet.starter_web_subnet.id
  display_name = "${var.prefix}-nlb"
  is_private=false
}

resource "oci_network_load_balancer_network_load_balancers_backend_sets_unified" "starter_nlb_bes" {
  name                     = "${var.prefix}-nlb-bes"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.starter_nlb.id
  policy                   = "FIVE_TUPLE"  
  health_checker {
    port                   = "8080"
    protocol               = "TCP"
    timeout_in_millis      = 10000
    interval_in_millis     = 10000
    retries                = 3
  }
}

resource "oci_network_load_balancer_listener" "starter_listener" {
    #Required
    name = "${var.prefix}-nlb-listener"
    network_load_balancer_id = oci_network_load_balancer_network_load_balancer.starter_nlb.id
    default_backend_set_name = "${var.prefix}-nlb-bes"
    port = 8080
    protocol = "TCP"
    depends_on = [
        oci_network_load_balancer_network_load_balancers_backend_sets_unified.starter_nlb_bes 
    ]    
}

resource "oci_network_load_balancer_backend" "starter_nlb_be" {
    #Required
    backend_set_name = "${var.prefix}-nlb-bes"
    network_load_balancer_id = oci_network_load_balancer_network_load_balancer.starter_nlb.id
    port = 8080

    #Optional
    is_backup = false
    is_drain = false
    is_offline = false
    name = "${var.prefix}-nlb-be"
    target_id = oci_core_instance.starter_compute.id
    weight = 1

    depends_on = [
        oci_network_load_balancer_network_load_balancers_backend_sets_unified.starter_nlb_bes 
    ]
}
