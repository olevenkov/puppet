class greylog::landing($ensure='present') {
  if $ensure == 'present' {
    file { "/home/greylog/apps/landing":
      ensure => directory,
      owner  => 'greylog',
      group  => 'greylog';
    }
  } elsif $ensure == 'absent' {
    file { "/home/greylog/apps/landing":
      ensure  => 'absent',
      recurse => true,
      force   => true;
    }
  } else {
    fail "'$ensure' is not supported. Please use 'present' or 'absent'."
  }
}
