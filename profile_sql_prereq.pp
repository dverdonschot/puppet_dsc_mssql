class profile::profile_mssql_prereq::master {

    # Disable dhcp on second network interface for hearthbeat lan
        $dhcpdisabled = hiera('profiles::profile_mssql_prereq::dsc_netipinterface', {})
        create_resources(dsc_netipinterface, $dhcpdisabled)

    # Set static IP adress on second network interface for heartbeat lan
        $staticipv4 = hiera('profiles::profile_mssql_prereq::dsc_ipaddress', {})
        create_resources(dsc_ipaddress, $staticipv4)

    # Create required folders
        $files =  hiera('profiles::profile_mssql_prereq::dsc_file', {})
        create_resources(dsc_file, $files)
    
    # Create disks with mounpoint
        $datavolume =  hiera('profiles::profile_mssql_prereq::dsc_diskaccesspath', {})
        create_resources(dsc_diskaccesspath, $datavolume)

}

