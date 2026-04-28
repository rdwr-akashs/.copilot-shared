# Repository Categories — rdwr Bitbucket Workspace

> **Last updated:** 2026-04-27 | **Total repos:** 90+
> Use this to quickly filter which repos to search for a given question.

## Category: Core Services (DefenseFlow)

These are the main application backend services. **Search these first** for API contracts, business logic, and service integrations.

| Repo | Description | PE-Related? |
|---|---|---|
| the current repo | Policy Editor — current workspace | ✅ Self |
| `kvision_cyber_controller_core` | Cyber Controller (DefenseFlow) core | ✅ Calls PE |
| `kvision_dp_inline_config` | DP Inline Configurator | ✅ Calls PE |
| `kvision_configuration_service` | Configuration Service — RBAC, config proxy | ✅ Calls PE |
| `kvision_vrm` | VRM — Vision Reporter Module | ✅ Calls PE |
| `kvision_reporter` | Reporting service | ⚠️ Maybe |
| `kvision_collector` | Data collector | ⚠️ Maybe |
| `kvision_formatter` | Data formatter | ❌ |
| `kvision_scheduler` | Task scheduler | ❌ |
| `kvision_vdirect` | vDirect integration | ❌ |
| `kvision_ssli` | SSL Inspection | ❌ |
| `kvision_data_polling_mgr` | Data polling manager | ❌ |
| `kvision_data_persist_service` | Data persistence | ❌ |
| `kvision_data_polling_scheduler` | Polling scheduler | ❌ |
| `kvision_config_sync_service` | Config sync | ⚠️ Maybe |
| `kvision_assist_service` | AI assist service | ❌ |
| `kvision_dns_notify_listener` | DNS notification listener | ❌ |
| `kvision_snmp_trap_collector` | SNMP trap collector | ❌ |
| `kvision_anomaly_detection_engine` | Anomaly detection | ❌ |
| `kvision_ted` | TED service | ❌ |

## Category: Core Libraries & APIs

Shared libraries and API definitions. **Search these** when tracing shared DTOs, utilities, or driver contracts.

| Repo | Description | PE-Related? |
|---|---|---|
| `df_core` | DefenseFlow core library | ✅ Shared DTOs |
| `kvision_libs` | Shared Java libraries (kvision) | ✅ Common utils |
| `vision_libs` | Shared Java libraries (vision) | ⚠️ Maybe |
| `vision_core` | Vision core library | ⚠️ Maybe |
| `df-driver-api` | DefenseFlow driver API definitions | ✅ Driver contracts |
| `common_pe_drivers` | PE driver packages | ✅ Direct |
| `df_dppack` | DP package management | ⚠️ Maybe |

## Category: UI / Frontend

Frontend applications and component libraries. **Search these** for UI patterns, component usage, and frontend integration.

| Repo | Description | PE-Related? |
|---|---|---|
| `webui_components` | Shared UI components (legacy) | ✅ UI dependency |
| `webui_design_sys` | Design system (`webui-design-system`) | ✅ UI dependency |
| `webui_core` | Core web UI framework | ✅ UI dependency |
| `kvision_webui` | Main kvision web UI shell | ✅ Embeds PE |
| `df_ui_components` | DefenseFlow UI components | ⚠️ Maybe |
| `kvision_alteon_automation_ui` | Alteon automation UI | ❌ |
| `webui_policy_editor_poc` | PE UI proof of concept | ⚠️ Legacy/POC |
| `webui_base_images` | Base images for UI builds | ❌ |
| `df-dashboard` | DefenseFlow dashboard | ⚠️ Maybe |

## Category: Infrastructure & Deployment

DevOps, deployment, and infrastructure repos. **Search these** for deployment configs, Docker, nginx, and CI/CD.

| Repo | Description |
|---|---|
| `kvision_deploy` | Deployment orchestration (kvision) |
| `common_deploy` | Common deployment tools |
| `kvision_dc_nginx` | nginx configuration |
| `common_infra_nginx` | Common nginx infra |
| `kvision_postgres` | PostgreSQL config |
| `kvision_infra_rabbitmq` | RabbitMQ config |
| `kvision_infra_redis` | Redis config |
| `kvision_infra_monitoring` | Monitoring (Prometheus, etc.) |
| `kvision_infra_fluentd` | Log aggregation |
| `kvision_infra_efk` | EFK stack |
| `common_infra_metallb` | MetalLB load balancer |
| `common_infra_lls` | License server |
| `kvision_infra_tomcat_base` | Tomcat base image |
| `kvision_infra_snmp4j` | SNMP library |
| `kvision_infra_cadvisor` | cAdvisor monitoring |
| `kvision_infra_ipv6nat` | IPv6 NAT |
| `kvision_infra_mariadb` | MariaDB config |
| `kvision_lls` | License server (kvision) |
| `kvision_base_image` | Base Docker image |
| `kvision_exabgp` | ExaBGP integration |
| `kvision_3rd_infras` | Third-party infrastructure |
| `common_cluster_installer` | Cluster installation |
| `kvision_ansible_templates` | Ansible deployment templates |
| `kvision_kibana` | Kibana dashboards |

## Category: Tools & CI

Build tools, testing infra, and automation.

| Repo | Description |
|---|---|
| `common_devops_tools` | Shared DevOps tooling |
| `kvision_tools` | kvision CLI tools |
| `kvision_cli` | CLI utilities |
| `common_kautomation_infra` | Automation framework |
| `common_kautomation_amqp` | AMQP automation |
| `kvision_manifest` | Service manifests |
| `kvision_upgrade` | Upgrade service |
| `kvision_os_upgrade` | OS upgrade |
| `kvision_fnm_os_upgrader` | FNM OS upgrader |
| `common_nexus` | Nexus repository |
| `oas_validator` | OpenAPI spec validator |
| `kvision_rest_api_doc` | REST API documentation |

## Category: Testing & Automation

| Repo | Description |
|---|---|
| `auto-df-infra` | DF automation infrastructure |
| `auto-df-tests` | DF automation tests |
| `vision_testing_tools` | Vision testing utilities |

## Category: Alerts & Events

| Repo | Description |
|---|---|
| `kvision_rt_alert` | Real-time alerts |
| `kvision_alerts` | Alert management |
| `vision_rt_alert` | Vision real-time alerts |
| `vision_alerts` | Vision alerts |
| `common_events_query_engine` | Event query engine |
| `common_df_custom_operation` | DF custom operations |

## Category: Vision (Legacy/Related)

| Repo | Description |
|---|---|
| `vision_collector` | Vision data collector |
| `vision_reporter` | Vision reporter |
| `vision_tor_feed` | Vision TOR feed |
| `vision_scheduler` | Vision scheduler |
| `vision_dependency_manager` | Vision dependency manager |
| `vision_health` | Vision health check |
| `vision_vrm` | Vision VRM |
| `kvision_health` | kvision health check |
| `kvision_ha_operator` | HA Kubernetes operator |
| `kvision_ha_orchestrator` | HA orchestrator |
| `kvision_es_data_migration` | Elasticsearch data migration |
| `kvision_tor_feed` | TOR feed service |
| `common_vantage` | Vantage integration |

## Category: Documentation

| Repo | Description |
|---|---|
| `ai_resources` | AI/ML resources |
| `ams_docs` | AMS documentation |
| `cybercontroller_docs` | Cyber Controller docs |
| `visionhelp` | Vision help content |
| `kvision_help` | kvision help content |
| `aae_vdirect_workflows` | vDirect workflow docs |

---

## Quick Filter Cheat Sheet

| Question | Search These Categories |
|---|---|
| Who calls PE's API? | Core Services (PE-related ✅ only) |
| Who uses this shared DTO? | Core Libraries + Core Services |
| How is PE deployed? | Infrastructure, Deployment |
| Where is this UI component used? | UI / Frontend |
| Who uses RabbitMQ? | Core Services + Infrastructure |
| Who depends on this Maven artifact? | Core Libraries + Core Services (read pom.xml) |
| How does auth/RBAC work? | `kvision_configuration_service`, `kvision_dc_nginx` |
| What nginx routes exist? | `kvision_dc_nginx`, `common_infra_nginx` |

