class logstash {
  if $::runit_installed == 'true' {
    include logstash::install
  } else {
    notice 'Not installing Logstash as the Runit system process is missing.'
  }
}
