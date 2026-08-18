# Use this hook to configure the litestream-ruby gem.
# All configuration options will be available as environment variables, e.g.
# config.replica_bucket becomes LITESTREAM_REPLICA_BUCKET
# This allows you to configure Litestream using Rails encrypted credentials,
# or some other mechanism where the values are only available at runtime.

Rails.application.configure do
  # IONOS Object Storage (S3-compatible) — voir docs/backup-restore.md pour la procédure
  # de création du bucket/clé côté IONOS. Credentials sous `bin/rails credentials:edit` :
  #
  #   litestream:
  #     replica_bucket: <nom-du-bucket>
  #     replica_region: <region-ionos, ex: eu-central-3>
  #     replica_endpoint: <endpoint-ionos, ex: s3.eu-central-3.ionoscloud.com>
  #     replica_key_id: <access-key>
  #     replica_access_key: <secret-key>
  #     dashboard_username: ...
  #     dashboard_password: ...
  litestream_credentials = Rails.application.credentials.litestream

  config.litestream.replica_bucket = litestream_credentials&.replica_bucket
  config.litestream.replica_key_id = litestream_credentials&.replica_key_id
  config.litestream.replica_access_key = litestream_credentials&.replica_access_key
  config.litestream.replica_region = litestream_credentials&.replica_region
  config.litestream.replica_endpoint = litestream_credentials&.replica_endpoint

  # Dashboard Litestream (montée par le gem) protégée par auth basique.
  config.litestream.username = litestream_credentials&.dashboard_username
  config.litestream.password = litestream_credentials&.dashboard_password
end
