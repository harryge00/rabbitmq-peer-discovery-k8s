-define(CONFIG_MAPPING,
         #{
          master_scheme                         => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "MESOS_MASTER_SCHEMA",
                                                   default_value = "http"
                                                  },
          master_host                           => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "MESOS_MASTER_HOST",
                                                   default_value = "master.mesos"
                                                  },
          master_port                           => #peer_discovery_config_entry_meta{
                                                   type          = integer,
                                                   env_variable  = "MESOS_MASTER_PORT",
                                                   default_value = 8080
                                                  },
          k8s_token_path                     => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "K8S_TOKEN_PATH",
                                                   default_value = "/var/run/secrets/kubernetes.io/serviceaccount/token"
                                                  },
          k8s_cert_path                      => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "K8S_CERT_PATH",
                                                   default_value = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
                                                  },
          k8s_namespace_path                 => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "K8S_NAMESPACE_PATH",
                                                   default_value = "/var/run/secrets/kubernetes.io/serviceaccount/namespace"
                                                  },
          marathon_app_id                   => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "MARATHON_APP_ID",
                                                   default_value = "/rabbitmq"
                                                  },
          k8s_address_type                   => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "K8S_ADDRESS_TYPE",
                                                   default_value = "ip"
                                                  },
          k8s_hostname_suffix                => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "K8S_HOSTNAME_SUFFIX",
                                                   default_value = ""
                                                  }
         }).
