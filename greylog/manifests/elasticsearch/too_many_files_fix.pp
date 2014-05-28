#####
# See: http://www.elasticsearch.org/tutorials/2011/04/06/too-many-open-files.html
#
# NOTE: This will not work for processes being run under Runit
class greylog::elasticsearch::too_many_files_fix {
  file {
    "/etc/security/limits.d/greylog-elasticsearch.conf":
      ensure => "file",
      source => "puppet:///modules/greylog/elasticsearch/too_many_files_fix/greylog-elasticsearch.conf",
      owner  => "root",
      group  => "root",
      mode   => '0644';
  }
}
