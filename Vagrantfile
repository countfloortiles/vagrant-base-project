# -*- mode: ruby -*-
# vi: set ft=ruby :

# This is a smart Vagrantfile which uses JSON configurations to determine the
# systems architecture for a multi-node project.

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
                service_config["ip_pool"]["list"].each { |ip_address| ip_pool << IPAddr.new(ip_address) }
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
                        "service" => service_name,
                        "role" => node_config["role"],
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


        # Initialize each vagrant machine instance.
        processed.each do |instance_name, instance_config|
            Vagrant.configure("2") do |config|
                config.vm.define instance_name do |instance|

                    # Configure virtual hardware.
                    case instance_config["provider"]
                    when "virtualbox"
                        instance.vm.provider :virtualbox do |virtualbox|
                            params = [
                                "modifyvm", :id,
                                "--name", instance_name
                            ]
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


                    # Set up synced directories.
                    {
                        # Use /synced/common/ directory on guest machine for storing
                        # files that should be available to all instances.
                        "synced_common.#{instance_name}" => {
                            :host_dir => "synced/#{instance_config["service"]}/common/",
                            :guest_dir => "/synced/common/"
                        },
                        # Use /synced/role/ directory on guest machine for storing files
                        # that should be available to all instances of this role.
                        "synced_role.#{instance_name}" => {
                            :host_dir => "synced/#{instance_config["service"]}/#{instance_config["role"]}/",
                            :guest_dir => "/synced/role/"
                        },
                        # Use /synced/instance/ directory on guest machine for storing
                        # files that should be available only to this instance.
                        "synced_instance.#{instance_name}" => {
                            :host_dir => "synced/#{instance_config["service"]}/instance/#{instance_name}/",
                            :guest_dir => "/synced/instance/"
                        }
                    }.each do |synced_id, synced_config|
                        # Create host directory if it doesn't exist.
                        if !FileTest::directory?(synced_config[:host_dir])
                            FileUtils.mkdir_p(synced_config[:host_dir])
                        end
                        instance.vm.synced_folder synced_config[:host_dir], synced_config[:guest_dir], { id: synced_id, nfs: true }
                    end


                    # Provision instance.
                    instance_config["provision"].each do |provision|
                        case provision["provisioner"]
                        when "shell"
                            instance.vm.provision :shell, :path => "provision/shell/#{provision["path"]}"
                        end
                    end
                end
            end
        end

        # Copy {service name}.processed.json to make it available to the instances
        # of the service in /synced/common/ on each guest machine.
        FileUtils.cp("infrastructure/processed/#{service_name}.processed.json", "synced/#{service_name}/common/#{service_name}.processed.json")
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
