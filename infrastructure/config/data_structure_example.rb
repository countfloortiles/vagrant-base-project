system => {
    # Each service is a discrete module providing a well defined set of functionality.
    :services => {
        "analytics_api" => {
            :topology => "pool",
            :ip_range => {:start => "192.168.0.0", :end => "192.168.0.255"},

            # A pool of workers should not need to know about each other.  Put a load
            # balancer in front of the worker pool.
            :workers => {
                :quantity => 2,
                :role => "api_worker",
            },
            :lb => {
                :role => "lb",
            },
        },

        "riak" => {
            :topology => "cluster",
            :ip_range => {:start => "192.168.1.0", :end => "192.168.1.255"},

            # A cluster of nodes should know about each other.  Put a load balancer
            # int front of the cluster of nodes.
            :nodes => {
                :quantity => 5,
                :role => "riak_node",
            },
            :lb => {
                :role => "lb",
            },
        },
    },

    # Each role can be reused multiple times.
    :roles => {
        # Want load balancers: anything stable will work; load balancers do
        # simple work to route many requests in a short time frame.
        "lb" => {
            :hardware => {:memory => 128, :cpus => 2},
            :box => "lucid64",
            :box_url => "http://files.vagrantup.com/lucid64.box",
            :synced_dir => "lb/",
            :provision => [
                # Provision the basics.
                {:provisioner => :shell, :path => "bootstrap/aliases.sh"},
                {:provisioner => :shell, :path => "bootstrap/curl.sh"},
                {:provisioner => :shell, :path => "bootstrap/htop.sh"},
                {:provisioner => :shell, :path => "bootstrap/vim.sh"},
                {:provisioner => :shell, :path => "bootstrap/git.sh"},

                # HAProxy
                {:provisioner => :shell, :path => "bootstrap/haproxy.sh"},
            ],
        },

        # Want API instances to be fast workers that handle concurrency well.
        "api_worker" => {
            :hardware => {:memory => 512, :cpus => 8},
            :box => "lucid64",
            :box_url => "http://files.vagrantup.com/lucid64.box",
            :synced_dir => "api/",
            :provision => {
                # Provision the basics.
                {:provisioner => :shell, :path => "bootstrap/aliases.sh"},
                {:provisioner => :shell, :path => "bootstrap/curl.sh"},
                {:provisioner => :shell, :path => "bootstrap/htop.sh"},
                {:provisioner => :shell, :path => "bootstrap/vim.sh"},
                {:provisioner => :shell, :path => "bootstrap/git.sh"},

                # node.js
                {:provisioner => :shell, :path => "bootstrap/nodejs.sh"},
            },
        },

        # Want Riak instances to be small and cheap so that we can have improved
        # availablility by using many affordable instances.
        "riak_node" => {
            :hardware => {:memory => 256, :cpus => 4},
            :box => "lucid64",
            :box_url => "http://files.vagrantup.com/lucid64.box",
            :synced_dir => "riak/",
            :provision => {
                # Provision the basics.
                {:provisioner => :shell, :path => "bootstrap/aliases.sh"},
                {:provisioner => :shell, :path => "bootstrap/curl.sh"},
                {:provisioner => :shell, :path => "bootstrap/htop.sh"},
                {:provisioner => :shell, :path => "bootstrap/vim.sh"},
                {:provisioner => :shell, :path => "bootstrap/git.sh"},

                # Riak
                {:provisioner => :shell, :path => "bootstrap/riak.sh"},
            },
        },
    },
}
