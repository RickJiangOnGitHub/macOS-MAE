#!/bin/bash

############ Server details ############

hostName="172.17.100.208"
portNo="80"
protocol="http"

############ Server details ############

SUPPORT="assetexplorer-support@manageengine.com"
PRODUCT="AssetExplorer"

COMPUTERNAME=`hostname`
OUTPUTFILE="$COMPUTERNAME.xml"


main()
{
	echo "##### Scanning Started #####"
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><DocRoot>" >$OUTPUTFILE
	constructXML "ComputerName" "hostname"
	constructXML "OS_Category" "uname -s"
	echo "<Hardware_Info>" >>$OUTPUTFILE
	constructXML "OS_Category" "uname -s"
	constructXML "OS_Information" "cat /proc/version"
        constructXML "OS_Information" "cat /etc/os-release"
	constructXML "OS_InformationRedhat" "cat /etc/redhat-release"
	constructXML "OS_InformationDebian" "cat /etc/debian_version"
	constructXML "OS_InformationSuSE" "cat /etc/SuSE-release"
	constructXML "OS_InformationSuSE" "cat /etc/lsb-release"
	constructXML "Memory_Information" "cat /proc/meminfo"
	constructXML "Computer_Information" "hostname -f"
	constructXML "Computer_Information" "hostname"
        constructXML "Last_Logged_In_User" "last -w | awk '{print \$1 \" \" \$3}'"
	constructXML "CPU_Information" "cat /proc/cpuinfo"
	constructXML "IDE-disk-list" "ls /proc/ide"
	constructXML "IDE_model" "cat /proc/ide/hd*/model"
	constructXML "IDE_Capacity" "cat /proc/ide/hd*/capacity"
	constructXML "IDE_Media" "cat /proc/ide/hd*/media"
	constructXML "IDE_Driver" "cat /proc/ide/hd*/driver"
	constructXML "Disk_Space" "df -k"
	constructXML "NIC_Name" "lspci"
	constructXML "NIC_Name" "/sbin/lspci"
	constructXML "NIC_Info" "/sbin/ifconfig"
	constructXML "USB_Contoller" "grep 'USB Controller' /proc/pci"
	constructXML "ServiceTag_BIOS" "/usr/sbin/dmidecode --type bios --type system"
	constructXML "Memory_Module" "/usr/sbin/dmidecode --type memory device"
	constructXML "Complete_dmidecode_execution" "/usr/sbin/dmidecode"
	constructXML "IDE_Disk" "lshw -C disk"
	echo "</Hardware_Info>" >>$OUTPUTFILE
	echo "<Software_Info>" >>$OUTPUTFILE
	constructXML "Installed_Softwares" "rpm -qa --queryformat '%{NAME}::%{VERSION}::%{RELEASE}::%{SUMMARY}\n'"
	constructXML "debian_softwares" "dpkg -l | tail -n +6"
	echo "</Software_Info>" >>$OUTPUTFILE
	echo "</DocRoot>" >>$OUTPUTFILE
	echo "##### Scanning completed #####"
	#echo $data
	pushData
}

constructXML()
{
	##Need to replace the < into &lt; , > into &gt; and & into &amp;#####
	echo "<$1><command>$2</command><output><![CDATA[">>$OUTPUTFILE
	eval $2 >> $OUTPUTFILE 2>&1
	echo "]]></output></$1>" >>$OUTPUTFILE
}

pushData()
{
        data=$(cat $OUTPUTFILE)
        eval "type curl > /dev/null 2>&1"

        if [ $? -ne 0 ]
        then
		#"Pushing the scanned xml file using wget command"
	        wget "$protocol://$hostName:$portNo/discoveryServlet/WsDiscoveryServlet?COMPUTERNAME=$COMPUTERNAME" --post-file=./$COMPUTERNAME.xml --header="Content-Type:text/xml" > /dev/null 2>&1
                if [ $? -ne 0 ]
                then
                        echo "curl or wget is not installed, so could not post the scan data to $PRODUCT, You can import the  $COMPUTERNAME.xml available in th
e current directory into $PRODUCT using Stand Alone Workstations Audit. Executing the curl command will lead to the installation."
                else
                        rm -f $OUTPUTFILE
			#Deleting the temp file which got created by using wget
			rm -f "WsDiscoveryServlet?COMPUTERNAME=$COMPUTERNAME"
                        echo "Successfully scanned the system data, Find this machine details in $PRODUCT server."
                fi
                exit 1
        fi

        curl --header "Content-Type: text/xml" --data-binary @$OUTPUTFILE "$protocol://$hostName:$portNo/discoveryServlet/WsDiscoveryServlet?COMPUTERNAME=$COMPUTERNAME"
        if [ $? -ne 0 ]
        then
           echo "$PRODUCT is not reachable. You can import the  $COMPUTERNAME.xml available in the current directory into $PRODUCT using Stand Alone Workstation
s Audit. For further queries, please contact $SUPPORT."
        else
           rm -rf $OUTPUTFILE
           echo "Successfully scanned the system data, Find this machine details in $PRODUCT server."
        fi
}


main $*
