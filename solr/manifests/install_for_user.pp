define solr::install_for_user($port,
                              $environment='development',
                              $elevate='puppet:///modules/solr/configs/elevate.xml',
                              $schema='puppet:///modules/solr/configs/schema.xml',
                              $solrconfig='puppet:///modules/solr/configs/solrconfig.xml',
                              $spellings='puppet:///modules/solr/configs/spellings.txt',
                              $stopwords='puppet:///modules/solr/configs/stopwords.txt',
                              $stopwords_en='puppet:///modules/solr/configs/stopwords_en.txt',
                              $synonyms='puppet:///modules/solr/configs/synonyms.txt',
                              $protwords='puppet:///modules/solr/configs/protwords.txt') {
  $user = $name

  # Just for newrelic
  $key = "*******************" 
  $application_name = "${user}-solr"

  $solr_home         = "/home/${user}/solr"
  $solr_data_home    = "${solr_home}/data"
  $solr_newrelic_jar = "${solr_home}/newrelic/newrelic.jar"
  $solr_jetty_home   = "/usr/share/solr/jetty"
  $solr_jetty_jar    = "${solr_jetty_home}/start.jar"
  $solr_jetty_xml    = "${solr_jetty_home}/etc/jetty.xml"

  include solr

  runit::install_for_user { $user: }

  File {
    owner  => $user,
    group  => $user,
  }

  file {
    [$solr_home, $solr_data_home, "${solr_home}/conf"]:
      ensure => directory,
      mode   => 0755;

    "${solr_home}/newrelic":
      ensure  => directory,
      source  => 'puppet:///modules/newrelic',
      recurse => true;

    "${solr_home}/conf/elevate.xml":
      ensure => present,
      source => $elevate;

    "${solr_home}/conf/schema.xml":
      ensure => present,
      source => $schema;

    "${solr_home}/conf/solrconfig.xml":
      ensure => present,
      source => $solrconfig;

    "${solr_home}/conf/spellings.txt":
      ensure => present,
      source => $spellings;

    "${solr_home}/conf/stopwords.txt":
      ensure => present,
      source => $stopwords;

    "${solr_home}/conf/stopwords_en.txt":
      ensure => present,
      source => $stopwords_en;

    "${solr_home}/conf/synonyms.txt":
      ensure => present,
      source => $synonyms;

    "${solr_home}/conf/protwords.txt":
      ensure => present,
      source => $protwords;

    "${solr_home}/newrelic/newrelic.yml":
      ensure  => present,
      mode    => 0600,
      content => template('npd/newrelic.yml.erb');
  }

  runit::user_service {
    "${user}-solr":
      content              => template('solr/run_script.erb'),
      sv_wait              => 60,
      check_script_content => template('solr/check_script.erb'),
      user                 => $user,
      enable               => true;
  }

}
