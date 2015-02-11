module Beaker
  class VBox < Beaker::Hypervisor

    def initialize(vbox_hosts, options)
      require 'rubygems' unless defined?(Gem)
      begin
        require 'virtbox'
      rescue LoadError
        raise "Unable to load virtbox, please ensure it is installed!"
      end
      @logger = options[:logger]
      @options = options
      @hosts = vbox_hosts
      #check preconditions for fusion
      @hosts.each do |host|
        raise "You must specify a snapshot for VBox instances, no snapshot defined for #{host.name}!" unless host["snapshot"]
      end
    end

    def provision
      @hosts.each do |host|
        vm_name = host["vmname"] || host.name
        vm = VirtBox::VM.new vm_name
        raise "Could not find VM '#{vm_name}' for #{host.name}!" unless vm.exists?

        vm_snapshots = vm.snapshots
        if vm_snapshots.nil? or vm_snapshots.empty?
          raise "No snapshots available for VM #{host.name} (vmname: '#{vm_name}')"
        end

        available_snapshots = vm_snapshots.sort.join(", ")
        @logger.notify "Available snapshots for #{host.name}: #{available_snapshots}"
        snap_name = host["snapshot"]
        raise "Could not find snapshot '#{snap_name}' for host #{host.name}!" unless vm.snapshots.include? snap_name

        @logger.notify "Reverting #{host.name} to snapshot '#{snap_name}'"
        start = Time.now
        vm.revert_to_snapshot snap_name
        time = Time.now - start
        @logger.notify "Spent %.2f seconds reverting" % time

        @logger.notify "Resuming #{host.name}"
        start = Time.now
        vm.start :headless => true
        sleep 1
        time = Time.now - start
        @logger.notify "Spent %.2f seconds resuming VM" % time
      end
      end #revert_fusion

      def cleanup
        @logger.notify "No cleanup for VBox boxes"
      end

  end
end
