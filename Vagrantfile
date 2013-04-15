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

    # For each service name, load corresponding *.processed.json data file if it
    # exists, avoiding the need to create instances and assign IP addresses.
    # Otherwise create the service config data.
    system["services"].each do |service_name, service_config|
        processed = {}

        filename = "infrastructure/processed/#{service_name}.processed.json"
        if File.exists?(filename)
            processed = JSON.parse( File.read(filename) )
        else
            # Generate a pool of IP addresses available for use in this service.
            ip_pool = []
            if service_config["ip_pool"].has_key?("range")
                require "ipaddr"
                range_start = IPAddr.new service_config["ip_pool"]["range"]["start"]
                range_end = IPAddr.new service_config["ip_pool"]["range"]["end"]

                current_ip = range_start
                while (current_ip <=> range_end) <= 0 do
                    ip_pool << current_ip
                    current_ip = current_ip.succ
                end
            end
            if service_config["ip_pool"].has_key?("list")
                ip_pool << service_config["ip_pool"]["list"]
            end

            # Derive configuration for each instance.
            service_config["nodes"].each do |node_config|
                for i in 0..(node_config["quantity"] - 1)
                    role = system["roles"][node_config["role"]]

                    instance_name = "#{service_name}.#{node_config["role"]}.#{i}"

                    # Assign an IP address at random from the pool of available IP addresses.
                    ip_address = ip_pool.sample
                    ip_pool.delete_at(ip_pool.index(ip_address))

                    processed[instance_name] = {
                        "provider" => role["provider"],
                        "virtual_hardware" => role["virtual_hardware"],
                        "box" => role["box"],
                        "box_url" => system["boxes"][role["box"]]["box_url"],
                        "ip_address" => ip_address.to_s,
                        "provision" => role["provision"]
                    }
                end
            end

            # Write file at #{filename} with JSON encoded #{processed} data structure.
            File.open(filename, 'w+') { |fh| fh.write( JSON.pretty_generate(processed) ) }
        end

        processed.each do |instance_name, instance_config|

            # Do vagrant machine instance setup.
            Vagrant.configure("2") do |config|
                config.vm.define instance_name do |instance|

                    # Configure virtual hardware.
                    case instance_config["provider"]
                    when "virtualbox"
                        instance.vm.provider :virtualbox do |virtualbox|
                            params = ["modifyvm", :id]
                            instance_config["virtual_hardware"].each do |attribute, value|
                                params << "--#{attribute}" << value
                            end
                            virtualbox.customize params
                        end
                    end

                    # Configure base box (the installed OS that will run on the VM).
                    instance.vm.box = instance_config["box"]
                    instance.vm.box_url = instance_config["box_url"]

                    # Configure networking, assigning IP address.
                    instance.vm.network :private_network, ip: instance_config["ip_address"]

                    # Provision instance.
                    #instance_config["provision"].each do |provision|
                    #    case provision["provisioner"]
                    #    when "shell"
                    #        instance.vm.provision :shell, :path => provision["path"]
                    #    end
                    #end
                end
            end
        end
    end
end

# Load JSON files describing system architecture, building each.  Config files must
# be named using *.config.json format.
Dir["infrastructure/config/*"].each do |filename|
    config_filename = filename.scan(/^.*\.config\.json$/i)
    if (config_filename.any?)
        setup( JSON.parse( File.read(config_filename[0]) ) )
    end
end
