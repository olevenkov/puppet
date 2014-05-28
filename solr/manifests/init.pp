class solr {
  include yum::repo::nature

  package {
    "solr":
      ensure   => latest,
      provider => 'yum',
      require  => Class['yum::repo::nature'];
  }
}
