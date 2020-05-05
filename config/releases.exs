import Config

config :postoffice, PostofficeWeb.Endpoint,
  secret_key_base: {:system, "SECRET_KEY_BASE", default: "12121212"}

config :postoffice, pubsub_project_name: {:system, "GCLOUD_PUBSUB_PROJECT_ID", default: "test"}

config :postoffice, Postoffice.Repo,
  username: {:system, "DB_USERNAME", default: "postgres"},
  hostname: {:system, "DB_HOST", default: "db"},
  password: {:system, "DB_PASSWORD", default: "postgres"},
  database: {:system, "DB_NAME", default: "myapp"},
  port: {:system, "DB_PORT", type: :integer, default: 5432},
  pool_size: {:system, "DB_POOL_SIZE", type: :integer, default: 20},
  queue_target: {:system, "DB_QUEUE_TARGET", type: :integer, default: 3000},
  show_sensitive_data_on_connection_error: false

# If K8S_CLUSTER env_variable is set we'll try to setup a k8s cluster
if System.get_env("K8S_CLUSTER") do
  config :libcluster,
    topologies: [
      k8s: [
        strategy: Elixir.Cluster.Strategy.Kubernetes,
        config: [
          mode: :ip,
          kubernetes_node_basename: System.get_env("K8S_NODE_BASENAME"),
          kubernetes_selector: System.get_env("K8S_SELECTOR"),
          kubernetes_namespace: System.get_env("K8S_NAMESPACE"),
          polling_interval: 10_000
        ]
      ]
    ]
end
