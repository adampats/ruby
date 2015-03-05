require 'fog'

vhost = 'vcenter.contoso.com'
vdc = 'datacentername'
vmname = 'vmname'
vuser = ARGV[0]
vpassword = ARGV[1]

vim = RbVmomi::VIM.connect host: vhost, user: vuser, password: vpassword
dc = vim.serviceInstance.find_datacenter(vdc) or fail "datacenter not found"

vm = dc.find_vm(vmname) or fail "vm not found"

puts vm.config.extraconfig


fog=Fog::Compute.new(:provider => "vsphere",
                     :vsphere_username => "username",
                     :vsphere_password=> "blah blah blah",
                     :vsphere_server => "netvcenter",
                     :vsphere_expected_pubkey_hash => "efd3c2da2332600ae973aa7418f3aabfd33165984d5d33e9cc35389794e58e3d")
