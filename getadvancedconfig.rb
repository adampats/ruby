require 'rbvmomi'

vhost = 'vcenter.contoso.com'
vdc = 'datacentername'
vmname = 'vmname'
vuser = ARGV[0]
vpassword = ARGV[1]

vim = RbVmomi::VIM.connect host: vhost, user: vuser, password: vpassword
dc = vim.serviceInstance.find_datacenter(vdc) or fail "datacenter not found"

vm = dc.find_vm(vmname) or fail "vm not found"

puts vm.config.extraconfig
