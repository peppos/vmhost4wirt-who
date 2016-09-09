#!/usr/bin/perl -w

use strict;
use warnings;

use VMware::VIRuntime;

$Util::script_version = "1.0";

my %opts = (
   datacenter => {
      type => "=s",
      help => "Datacenter name",
      required => 1,
   },
);

# read/validate options and connect to the server
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();

# find datacenter

my $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter');

# get all cluster under this datacenter
my $cluster_views = Vim::find_entity_views(view_type => 'ClusterComputeResource',
                                        begin_entity => $datacenter_view );
my $DC = $datacenter_view->name;

# get all hosts and VM under this datacenter
foreach my $cluster_view (@$cluster_views) {
        my $host_views = Vim::find_entity_views(view_type => 'HostSystem',
                                                begin_entity => $cluster_view,
                                                properties => [ 'name','hardware.cpuInfo.numCpuCores','hardware.cpuInfo.numCpuPackages','hardware.cpuInfo.numCpuThreads' ] );

        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine',
                                                begin_entity => $cluster_view );

        my $vm_list = Vim::find_entity_views(   view_type => 'VirtualMachine',
                                                begin_entity => $cluster_view,
                                                filter => { 'config.guestFullName' => qr/Linux/ },
                                                properties => [ 'name' ] );
        #:print Dumper @$vm_list;
        if(@$vm_list) {

        # print hosts
        # print cluster
        my $cluster_name = $cluster_view->name;
        #Util::trace(0, "$cluster_name :");

        my $count_host = 1;
        #print "  Hosts found:\n";
        foreach my $host_view (@$host_views) {
                print "$DC,$cluster_name," . $host_view->name.",";

                my $cpu_core = $host_view->get_property('hardware.cpuInfo.numCpuCores');
                my $cpu_pack = $host_view->get_property('hardware.cpuInfo.numCpuPackages');
                my $cpu_thread = $host_view->get_property('hardware.cpuInfo.numCpuThreads');
                print "$cpu_core,";
                print "$cpu_pack,";
                print "$cpu_thread\n";

                $count_host++;
        }
        }
        undef @$vm_list;
}

# disconnect from the server
Util::disconnect();
