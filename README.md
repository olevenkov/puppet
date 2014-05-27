NPG puppet-modules
--
This repo contains all the puppet modules the production puppetmaster utilizes (the master branch is checked out to /opt/repos/puppet-modules on the master).

Structure:

* modules/modulename
  * manifests/  Contains manifests, 1 file per class
  * tests/      Contains tests (can be as simple as *include class*)
  * files/      fileserver resources for this module
  * templates/  erb templates used by the module

Please use spaces only, 2 spaces per tab and follow the [puppet style guide](http://docs.puppetlabs.com/guides/style_guide.html)

Coming soon:

Long-lived test/ and staging/ branches
