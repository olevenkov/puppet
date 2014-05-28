class mongodb::client {
  package { "mongo-10gen":
    ensure => installed,
  }
}
