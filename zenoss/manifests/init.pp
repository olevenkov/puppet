#Placeholder, just defines a monitor script we want running fro now

class zenoss::truesightmonitor {
  include npgscripts::truesightreporter
  cron { "truesight-statsreporter":
    command => "/usr/local/scripts/truesight-errorreporter.py",
    user    => "root",
    hour    => "*",
    minute  => "*/5",
    ensure  => present,
  }
}
