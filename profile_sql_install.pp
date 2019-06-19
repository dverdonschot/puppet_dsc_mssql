class profile::profile_mssql_setup::master {

      #Dsc_group used to add users to local administrator accounts
        $usertolocaladmin = hiera('profiles::profile_mssql_setup::dsc_group', {})
        create_resources(dsc_group, $usertolocaladmin)
        
      #Install windows feature NetFramework45-core
        $windowsfeature = hiera('profiles::profile_mssql_setup::dsc_windowsfeature', {})
        create_resources(dsc_windowsfeature, $windowsfeature)

      #Perfrom sql setup
        $mssql = hiera('profiles::profile_mssql_setup::dsc_sqlsetup', {})
        create_resources(dsc_sqlsetup, $mssql)
        
      #Perfrom sql setup
        $mssqlconfig = hiera('profiles::profile_mssql_setup::dsc_sqlserverconfiguration', {})
        create_resources(dsc_sqlserverconfiguration, $mssqlconfig)
 
}

