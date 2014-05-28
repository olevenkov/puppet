class greylog::web::rvm_to_rbenv {
  file { '/home/greylog/var/log/nginx':
    ensure  => 'absent',
    force   => true,
    recurse => true;
  }
}
