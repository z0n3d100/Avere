// Copyright (C) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See LICENSE-CODE in the project root for license information.
package main

const (
	AvereAdminUsername        = "admin"
	MinNodesCount             = 3
	MaxNodesCount             = 16
	VfxtLogDateFormat         = "2006-01-02.15.04.05"
	VServerRangeSeperator     = "-"
	AverecmdRetryCount        = 30 // wait 5 minutes (ex. remove core filer gets perm denied for a while)
	AverecmdRetrySleepSeconds = 10
	AverecmdLogFile           = "~/averecmd.log"
	VServerName               = "vserver"

	// Platform
	PlatformAzure = "azure"

	// cluster sizes
	ClusterSkuUnsupportedTest = "unsupported_test_SKU"
	ClusterSkuProd            = "prod_sku"

	// cache policies
	CachePolicyClientsBypass                 = "Clients Bypassing the Cluster"
	CachePolicyReadCaching                   = "Read Caching"
	CachePolicyReadWriteCaching              = "Read and Write Caching"
	CachePolicyFullCaching                   = "Full Caching"
	CachePolicyTransitioningClients          = "Transitioning Clients Before or After a Migration"
	CachePolicyIsolatedCloudWorkstation      = "Isolated Cloud Workstation"
	CachePolicyCollaboratingCloudWorkstation = "Collaborating Cloud Workstation"

	CachePolicyIsolatedCloudWorkstationCheckAttributes      = "{}"
	CachePolicyCollaboratingCloudWorkstationCheckAttributes = "{'checkAttrPeriod':30,'checkDirAttrPeriod':30}"

	// user policies for admin.addUser Avere xml rpc call
	UserReadOnly  = "ro"
	UserReadWrite = "rw"
	AdminUserName = "admin"

	// filer class
	FilerClassNetappNonClustered = "NetappNonClustered"
	FilerClassNetappClustered    = "NetappClustered"
	FilerClassEMCIsilon          = "EmcIsilon"
	FilerClassOther              = "Other"
	FilerClassAvereCloud         = "AvereCloud"

	// VServer retry
	VServerRetryCount        = 60
	VServerRetrySleepSeconds = 10

	// filer retry
	FilerRetryCount        = 120
	FilerRetrySleepSeconds = 10

	// cluster stable, wait 40 minutes for cluster to become healthy
	ClusterStableRetryCount        = 240
	ClusterStableRetrySleepSeconds = 10

	// node change, wait 40 minutes for node increase or decrease
	NodeChangeRetryCount        = 240
	NodeChangeRetrySleepSeconds = 10

	// status's returned from Activity
	StatusComplete      = "complete"
	StatusCompleted     = "completed"
	StatusNodeRemoved   = "node(s) removed"
	CompletedPercent    = "100"
	NodeUp              = "up"
	AlertSeverityGreen  = "green"  // this means the alert is complete
	AlertSeverityYellow = "yellow" // this will eventually resolve itself

	// the cloud filer export
	CloudFilerExport = "/"

	// the share permssions
	PermissionsPreserve = "preserve" // this is the default for NFS shares
	PermissionsModebits = "modebits" // this is the default for the Azure Storage Share
)

// terraform schema constants - avoids bugs on schema name changes
const (
	controller_address           = "controller_address"
	controller_admin_username    = "controller_admin_username"
	controller_admin_password    = "controller_admin_password"
	run_local                    = "run_local"
	allow_non_ascii              = "allow_non_ascii"
	location                     = "location"
	platform                     = "platform"
	azure_resource_group         = "azure_resource_group"
	azure_network_resource_group = "azure_network_resource_group"
	azure_network_name           = "azure_network_name"
	azure_subnet_name            = "azure_subnet_name"
	ntp_servers                  = "ntp_servers"
	timezone                     = "timezone"
	dns_server                   = "dns_server"
	dns_domain                   = "dns_domain"
	dns_search                   = "dns_search"
	proxy_uri                    = "proxy_uri"
	cluster_proxy_uri            = "cluster_proxy_uri"
	image_id                     = "image_id"
	vfxt_cluster_name            = "vfxt_cluster_name"
	vfxt_admin_password          = "vfxt_admin_password"
	vfxt_node_count              = "vfxt_node_count"
	node_size                    = "node_size"
	node_cache_size              = "node_cache_size"
	vserver_first_ip             = "vserver_first_ip"
	global_custom_settings       = "global_custom_settings"
	vserver_settings             = "vserver_settings"
	enable_support_uploads       = "enable_support_uploads"
	user                         = "user"
	name                         = "name"
	password                     = "password"
	permission                   = "permission"
	core_filer                   = "core_filer"
	core_filer_name              = "name"
	fqdn_or_primary_ip           = "fqdn_or_primary_ip"
	cache_policy                 = "cache_policy"
	custom_settings              = "custom_settings"
	junction                     = "junction"
	namespace_path               = "namespace_path"
	core_filer_export            = "core_filer_export"
	export_subdirectory          = "export_subdirectory"
	azure_storage_filer          = "azure_storage_filer"
	account_name                 = "account_name"
	container_name               = "container_name"
	vfxt_management_ip           = "vfxt_management_ip"
	vserver_ip_addresses         = "vserver_ip_addresses"
	node_names                   = "node_names"
	junction_namespace_path      = "junction_namespace_path"
)
