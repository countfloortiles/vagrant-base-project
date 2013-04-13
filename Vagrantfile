# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile for working with abstract descriptions of multi-node systems.  Using
# simple abstractions we can shift the focus of configuration away from the specifics
# of each machine and toward the architecture of a system as a whole.  By working
# with a JSON description of a system's architecture we make it simple to imagine
# external tools to make working with systems architecture in virtualized and cloud
# environments more practical.


# Define the system_up function for running a system.
def setup(system)
    # Keep track of information about each machine built including details that
    # setup decides for the instance (i.e. instance name, IP address, etc.).
    built_instances = {}

    # Do setup.
    Vagrant.configure("2") do |config|
        system["services"].each do |service_name, service_desc|

            # Generate a pool of IP addresses available for use in this service.
            ip_pool = []
            if (service_desc["ip_pool"].has_key?("range"))
                require "ipaddr"
                range_start = IPAddr.new service_desc["ip_pool"]["range"]["start"]
                range_end = IPAddr.new service_desc["ip_pool"]["range"]["end"]

                current_ip = range_start
                while ((current_ip <=> range_end) <= 0) do
                    ip_pool << current_ip
                    current_ip = current_ip.succ
                end
            end
            if (service_desc["ip_pool"].has_key?("list"))
                ip_pool = service_desc["ip_pool"]["list"]
            end


            # Expect different communication needs for different topologies.
            case service_desc["topology"]
            when "pool"
                # Instances do not need to know about each other.
                instances = service_desc["workers"]
            when "cluster"
                # Instances should know about their peers.
                instances = service_desc["nodes"]
            end


            # Build each instance.
            for i in 0..instances["quantity"]
                role = system["roles"][instances["role"]]

                # Add instance to the list of built machines.  Begin empty and fill
                # in details as they become available; this will help with
                # troubleshooting when things go wrong.
                instance_name = "#{service_name}.#{instances["role"]}.#{i}"
                built_instances[instance_name] = {}

                # Build machine instance.
                config.vm.define instance_name do |instance|

                    # Configure virtual hardware.
                    case service_desc["provider"]
                    when "virtualbox"
                        instance.vm.provider :virtualbox do |virtualbox|
                            params = ["modifyvm", :id]
                            role["virtual_hardware"].each do |attribute, value|
                                params << "--#{attribute}" << value
                            end
                            virtualbox.customize params
                        end
                    end

                    # Configure base box (including OS).
                    instance.vm.box = role["box"]
                    instance.vm.box_url = system["boxes"][role["box"]]["box_url"]

                    # Assign an IP address at random from the pool of available IP addresses.
                    ip_address = ip_pool.sample
                    ip_pool.delete_at(ip_pool.index(ip_address))
                    print "[EVIE DEBUG] Assigning IP address to instance: #{ip_address}"
                    instance.vm.network :private_network, ip: ip_address.to_s

                    # Add info about this instance's assigned IP address.
                    built_instances[instance_name]["ip_address"] = ip_address

                    # Provision instance.
                    #role["provision"].each do |provision|
                    #    case provision["provisioner"]
                    #    when "shell"
                    #        instance.vm.provision :shell, :path => provision["path"]
                    #    end
                    #end
                end
            end

            # TODO: If "lb" defined for service then build instances.
        end
    end

    # Output details about the machines that were created.
    print "instances: \n" + JSON.pretty_generate(built_instances) + "\n"
end

# Load JSON files describing system architecture, building each.
Dir["systems_architecture/*"].each do |filename|
    filename = filename.scan(/^.*\.json$/i)
    if (filename.any?)
        setup(JSON.parse(File.read(filename[0])))
    end
end
