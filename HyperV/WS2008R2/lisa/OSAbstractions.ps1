#####################################################################
#
# OSAbstractions.ps1
#
# Description:
#    This file contains functions that are intended to hide
#    differences in the OS platforms supported by the
#    automation scripts.
#
#    Currently supported OS platforms:
#        Linux
#            RHEL
#            CentOS
#            SLES
#        BSD
#            FreeBSD
#
#    Current functions that provide some abstraction
#        GetOSDateString()
#        GetOSDos2unixCmd()
#        StartATDaemon()
#
#####################################################################



#####################################################################
#
# GetOSDateString()
#
#####################################################################
function GetOSDateTimeCmd ([System.Xml.XmlElement] $vm)
{
	<#
	.Synopsis
    	Return an OS specific date command to set the date/time
        on the VM.
    .Description
        Return a OS specific date/time command
        Linux:   "date mmddhhMMyyyy"
        FreeBSD: "date -n ccyymmddhhMM"
	#> 

    $dateTimeCmd = $null

    if ($vm)
    {
        if ($vm.os)
        {
            $now = [Datetime]::Now
            $os = $vm.os
            switch ($os)
            {
            #
            # Linux does not boot with the correct date/time
            #
            $LinuxOS   { $dateTimeCmd = "date " + $now.ToString("MMddHHmmyyyy") }

            #
            # FreeBSD does boot with correct date/time, so do nothing for now
            #
            $FreeBSDOS { $dateTimeCmd = "date -n " + $now.ToString("yyyyMMddHHmm") }

            #
            # Complain if it's an unknown OS type
            #
            default   { LogMsg 0 "Error: GetOSDateString() - unknown OS type of $($vm.os)" }
            }
        }
        else
        {
            LogMsg 0 "Error: $($vm.vmName) does not have the <os> xml property"
        }
    }

    return $dateTimeCmd
}


#####################################################################
#
# GetOSDos2unixCmd()
#
#####################################################################
function GetOSDos2unixCmd ([System.Xml.XmlElement] $vm, [String] $filename)
{
	<#
	.Synopsis
    	Return a dos2unix command that is OS specific
    .Description
        Return a OS specific dos2unix command string
        Linux:   dos2unix -q filename
        FreeBSD: dos2unix filename
	#> 

    if (-not $vm)
    {
        return $null
    }
    
    if (-not $filename)
    {
        return $null
    }

    $cmdString = $null
    if ($vm.os)
    {
        switch ( $($vm.os) )
        {
        #
        # We use the -q with Linux
        #
        $LinuxOS    { $cmdString = "dos2unix -q ${filename}" }
        
        #
        # No options with FreeBSD
        #
        $FreeBSDOS  { $cmdString = "dos2unix ${filename}" }

        #
        # Complain if it's an unknown OS type
        #
        default     { LogMsg 0 "Error: GetOSDos2unixString() - unknown OS type of $($vm.os)" }
        }
    }
    else
    {
        LogMsg 0 "Error: $($vm.vmName) does not have the <os> xml property"
    }

    return $cmdString
}


#####################################################################
#
# StartOSAtDaemon()
#
#####################################################################
function StartOSAtDaemon ([System.Xml.XmlElement] $vm)
{
	<#
	.Synopsis
    	Start the daemon that handles batch jobs
    .Description
        Start the daemon that handles batch jobs for the OS running on
        the VM.  Linux has the atd daemon.  FreeBSD uses crond.
	#> 

    if (-not $vm)
    {
        return $False
    }
    
    $daemonStarted = $False

    if ($vm.os)
    {
        switch ($($vm.os))
        {
        #
        # Linux uses atd
        #
        $LinuxOS    {
                        if ( (SendCommandToVM $vm "/etc/init.d/atd start") )
                        {
                             $daemonStarted = $True
                        }
                     }

        #
        # FreeBSD uses crond which is started by default
        #
        $FreeBSDOS  {
                        $daemonStarted = $True
                    }

        #
        # Complain if it's an unknown OS type
        #
        default     {
                        LogMsg 0 "Error: StaratOSAtDaemon() - unknown OS type of '$($vm.os)'"
                    }
        }
    }
    else
    {
        LogMsg 0 "Error: $($vm.vmName) does not have the <os> xml property"
    }

    return $daemonStarted
}


#####################################################################
#
# GetOSType()
#
#####################################################################
function GetOSType ([System.Xml.XmlElement] $vm)
{
    $os = bin\plink -i ssh\${sshKey} root@${hostname} "uname -s"

    switch ($os)
    {
        $LinuxOS   {}
        $FreeBSDOS {}
        default    { $os = "unknown" }
    }
    
    return $os
}


#####################################################################
#
# GetOSRunTestCaseCmd()
#
#####################################################################
function GetOSRunTestCaseCmd ([String] $os, [String] $testFilename, [String] $logFilename)
{
	<#
	.Synopsis
    	Build the command string to run the test case
    .Description
        Create a command string that will run the test case and
        also redirect STDOUT and STDERR to the logfile.
	#> 

    $runCmd = $null
    
    switch ($os)
    {
        $LinuxOS
            {
                $runCmd = "~/${testFilename} &> ~/${logFilename}"
            }

        $FreeBSDOS
            {
                $runCmd = "bash ~/${testFilename} > ~/${logFilename} 2>&1"
            }

        default
            {
        
                $runCmd = $null
            }
    }

    return $runCmd
}
