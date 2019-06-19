# Puppet DSC SQL

Puppet code examples for deploying Microsoft SQL Server using Powershell DSC

## Requirements

Puppet:
* Puppet server with hieradata (optionally with R10K)
* A profile module to place custom code for SQL deployments
* a hieradata windows sql server file named fqdn.yaml controlling the parameters of the profile code
* The following Puppetforge modules:
* [puppetlabs-powershell](https://forge.puppet.com/puppetlabs/powershell) - Powershell module for Puppet
* [puppetlabs-dsc](https://forge.puppet.com/puppetlabs/dsc) - Powershell DSC module for Puppet

Windows Client:
* Windows 2016 or 2019
* Working Puppet client
* Unpacked MSSQL 2017 image on a share or locally
* Extra nic and 2 extra disks for mountpoints
* The following Powershell modules installed:
* [DscResources](https://github.com/PowerShell/DscResources) - Powershell module for Powershell DSC
* [SqlServerDSC](https://github.com/PowerShell/SqlServerDsc) - Powershell module for MSSQL DSC

### Explanation Puppet Powershell DSC

With Powershell DSC you can use Powershell very similar to the way Puppet works.

Powershell DSC:

```
Import-DscResource -ModuleName SqlServerDsc

node localhost
{
        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
}

```

This script can be used to generate mof files and pull or push them to your servers.<br>
This process is however kind of complicated and would eventually require a seperate DSC environment for Windows.

But Microsoft and Puppetlabs have worked together, enabling almost all of the Powershell DSC commands to be used by Puppet.<br>
Puppet uses ruby files in the background that translate all standard modules to Puppet language.<br>
This results in code that is a litle bit different, but arguably easier to write.

Puppet language in profile:

```
class  profile::install{
       
        dsc_windowsfeature {'NetFramework45':
            dsc_name   => 'NET-Framework-45-Core',
            dsc_ensure => 'present',
        }
}        
```

As you can see every key and function used from Powershell DSC has a dsc_ in front of it.<br>
If you are ever in doubt about a key you can look them up by checking the Puppet ruby translation for Powershell DSC :

```
find / -name dsc_sqlsetup.rb | grep opt
  /opt/puppetlabs/puppet/cache/lib/puppet/type/dsc_sqlsetup.rb
```

There is also no import-dscresource and no node definition needed, as Puppet takes care of distribution and loading of modules.<br>
The Windows client does need to have the correct powershell modules installed for them to be used by Puppet.

## Controlling Puppet with Hieradata 

Using the import-resource function you can also use hieradata to enter the parameters:

In your profile you make a variable to get the hieradata.
Followed by a create resources that starts the function with the hieradata as input.

Puppet language in profile:

```
class profile::install{

        $windowsfeature = hiera('profile::install::dsc_windowsfeature', {})
        create_resources(dsc_windowsfeature, $windowsfeature)
}
```

Puppet hieradata <fdqn windows client>.yaml:

```
---
classes:
 - 'profile::install'

profile::install::dsc_windowsfeature
  netframework45:
    dsc_name: 'NET-Framework-45-Core'
    dsc_ensure: 'present'
  netframework35:
    dsc_name: 'NET-Framework-Core'
    dsc_source: '\\fileserver.company.local\images$\Win2k12R2\Sources\Sxs'
    dsc_ensure: 'present'
```

This way you use your profile to load functions and the hieradata to enter the data.

## Deploying MSSQL using DSC

Now let's deploy SQL.<br>
We again have to make a profile with the functions we want to use and the link to the hieradata.<br>
The functions will be windowsfeature, sqlsetup and sqlserverconfiguration

Profile:

```
class profile::profile_mssql_setup::master {

        #install windows feature NetFramework45-core
        $windowsfeature = hiera('profiles::profile_mssql_setup::dsc_windowsfeature', {})
        create_resources(dsc_windowsfeature, $windowsfeature)

        #perfrom sql setup
        $mssql = hiera('profiles::profile_mssql_setup::dsc_sqlsetup', {})
        create_resources(dsc_sqlsetup, $mssql)
        
        #perfrom sql setup
        $mssqlconfig = hiera('profiles::profile_mssql_setup::dsc_sqlserverconfiguration', {})
        create_resources(dsc_sqlserverconfiguration, $mssqlconfig)
 
}

``` 

Hieradata <fqdn windows client>.yaml:

```
---
classes:
 - 'profile::profile_mssql_setup::master'

profiles::profile_mssql_setup::dsc_windowsfeature:
  netframework45:
    dsc_name: 'NET-Framework-45-Core'
    dsc_ensure: 'present'

profiles::profile_mssql_setup::dsc_sqlsetup:
  installdefaultinstance:
    dsc_instancename: 'MSSQLSERVER'
    dsc_features: 'SQLENGINE'
    dsc_sqlsysadminaccounts: '<domain>\sql-group'
    dsc_installshareddir: 'C:\MSSQL\MDF01'
    dsc_installsharedwowdir: 'C:\MSSQL\MDF01WOW'
    dsc_instancedir: 'C:\MSSQL\MDF01'
    dsc_installsqldatadir: 'C:\MSSQL\LDF01\MSSQL13.MSSQLSERVER\MSSQL\Data'
    dsc_sqluserdbdir: 'C:\MSSQL\LDF01\MSSQL13.MSSQLSERVER\MSSQL\Data'
    dsc_sqluserdblogdir: 'C:\MSSQL\LDF01\MSSQL13.MSSQLSERVER\MSSQL\Data'
    dsc_sqltempdbdir: 'C:\MSSQL\LDF01\MSSQL13.MSSQLSERVER\MSSQL\Data'
    dsc_sqltempdblogdir: 'C:\MSSQL\LDF01\MSSQL13.MSSQLSERVER\MSSQL\Data'
    dsc_sqlbackupdir: 'C:\MSSQL\MDF01\MSSQL13.MSSQLSERVER\MSSQL\Backup'
    dsc_asservermode: 'MULTIDIMENSIONAL'
    dsc_asconfigdir: 'C:\MSOLAP\Config'
    dsc_aslogdir: 'C:\MSOLAP\Log'
    dsc_asbackupdir: 'C:\MSOLAP\Backup'
    dsc_astempdir: 'C:\MSOLAP\Temp'
    dsc_sourcepath: '\\<server share>\Installmedia\SQL2019RTM'
    dsc_updateenabled: 'False'
    dsc_forcereboot: 'False'
    dsc_sqltempdbfilecount: '4'
    dsc_sqltempdbfilesize: '1024'
    dsc_sqltempdbfilegrowth: '512'
    dsc_sqltempdblogfilesize: '1024'
    dsc_sqltempdblogfilegrowth: '512'
    #dsc_productkey: ''

profiles::profile_mssql_setup::dsc_sqlserverconfiguration:
  filestream_access_level:
    dsc_servername: 'localhost'
    dsc_instancename: 'MSSQLSERVER'
    dsc_optionname: 'filestream access level'
    dsc_optionvalue: '0'
    dsc_restartservice: 'False'

```

## Github repo puppet_dsc_sql

Included in the repo is the code used for a POC, it consists of:

* profile_sql_prereq.pp : prereq deployment steps like making mountpoints and setting IP's
* profile_sql_install.pp : SQL Installation and configuration
* fqdn.yaml : hieradata with inputs for the functions in the profiles
* Puppetfile : showing the modules used


## Authors

* **Dennis Verdonschot** - *Initial work* - [<name>](https://github.com/<name>)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details




