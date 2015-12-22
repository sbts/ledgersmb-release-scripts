#!/bin/bash

# import some functions that we need, like reading values from our config file.
ConfigFile=~/.lsmb-release

# set DEBUG=true to get dump of returned JSON for each command
DEBUG=true;

############
#  Check our arguments are sane
############
    if ! [[ ${1:-unknown} == 'stable' ]]; then
        printf "\n\n\n";
        printf "=====================================================================\n";
        printf "=====================================================================\n";
        printf "====  \$1 = %-10s                                            ====\n" "$1";
        printf "====      We can only make changes to the default link           ====\n";
        printf "====      when \$1 = stable                                       ====\n";
        printf "=====================================================================\n";
        printf "=====================================================================\n";
        printf "Exiting Now....\n\n\n";
        exit 1;
    fi
    if [[ -z $2 ]] && [[ -z $release_version ]]; then
        printf "\n\n\n";
        printf "=====================================================================\n";
        printf "=====================================================================\n";
        printf "====  Essential Argument not available:                          ====\n";
        printf "====      One of the following must be set                       ====\n";
        printf "====          \$release_version = %-10s                      ====\n" "$release_version";
        printf "====                        \$2 = %-10s                      ====\n" "$2";
        printf "=====================================================================\n";
        printf "=====================================================================\n";
        printf "Exiting Now....\n\n\n";
        exit 1;
    fi


libFile=` readlink -f ./bash-functions.sh`
[[ -f $libFile ]] && { [[ -r $libFile ]] && source $libFile; } || {
    printf "\n\n\n";
    printf "=====================================================================\n";
    printf "=====================================================================\n";
    printf "====  Essential Library not readable:                            ====\n";
    printf "====        %-51s  ====\n" $libFile;
    printf "=====================================================================\n";
    printf "=====================================================================\n";
    printf "Exiting Now....\n\n\n";
    exit 1;
}

# envsubst lets us safely substitute envvars into strings that would other wise need eval running on them. it is part of gettext-base
REQUIRE_bin "envsubst"
# jq is used to assist with Jason parsing. we could do away with it if it becomes a burdon
REQUIRE_bin "jq"


############
#  Test Config to make sure we have everything we need
############
HowToGetAPIkey() {
    cat <<-EOF
	Here is how to get your API key:
	
	    Go to your account page by....
	      * login
	      * click on down arrow next to "me" top right of page
	      * click on account settings
	      * at the bottom of the preferences tab
	    Click on the "Generate" button under the Releases API Key.
	    Copy and paste the key that appears into 
	        $ConfigFile
	            [sourceforge]
	            ApiKey    = YourKey
	
EOF
}

    while true; do
        # test for the apikey first so we can display help on getting it.
        if ( [[ ! -v cfgValue[sourceforge_ApiKey] ]] || [[ -z "${cfgValue[sourceforge_ApiKey]}" ]] ); then HowToGetAPIkey; fi #return; fi
        TestConfigInit;
        TestConfig4Key 'sourceforge' 'Project'             'ledgersmb'
        TestConfig4Key 'sourceforge' 'ReadlineHistory'     '/tmp/sourceforge.history'
        TestConfig4Key 'sourceforge' 'ApiKey'              'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
        TestConfig4Key 'sourceforge' 'DefaultFileTemplate' 'Releases/${Version_Stable}/ledgersmb-${Version_Stable}.tar.gz'
        TestConfig4Key 'sourceforge' 'download_label'      'Download Latest ($Version_Stable)'
        TestConfig4Key 'sourceforge' 'OS_List'             'windows mac linux bsd solaris others'
        if TestConfigAsk "Sourceforge Default Link Update"; then break; fi
    done


getCurrentProjectInfo() { # Stores result in Project_JSON   stores release.filename in Project_Filename    stores release.sf_platform_default in Project_OS_list
    # {"release": null, "platform_releases": {"windows": null, "mac": null, "linux": null}}
    local _URL="http://sourceforge.net/projects/${cfgValue[sourceforge_Project]}/best_release.json"
    declare -g Project_JSON=''
    declare -g Project_Filename=''
    printf "===================================================\n"
    printf "===================================================\n"
    printf "====   Retrieving Default Link for Project     ====\n"
    printf "====     %-35s   ====\n" "${cfgValue[sourceforge_Project]}"
    printf "===================================================\n"
    printf "===================================================\n\n"
    Project_JSON=`curl -s -X GET "$_URL"`
    ${DEBUG:-false} && {
        echo "\n==================================================="
        echo "==================================================="
        echo "==== Debug Output from getCurrentProjectInfo() ===="
        echo "==================================================="
        echo "==================================================="
        jq . <<< "$Project_JSON"
        echo
    }

    Project_Filename=`jq -c .release.filename <<< "$Project_JSON"`
    Project_OS_list=`jq -c .release.sf_platform_default <<< "$Project_JSON"`
    printf "filename ='%s'\n" "$Project_Filename"
    printf "OS list  ='%s'\n" "$Project_OS_list"
    echo
}


#### "${cfgValue[_]}"
updateSourceforge() { # $1 = New Version     $2 = New Date
    #https://sourceforge.net/p/forge/community-docs/Using%20the%20Release%20API/
    #https://sourceforge.net/p/forge/documentation/Allura%20API/
    
    local _DefaultFile="$(envsubst '$Version_Stable' <<<${cfgValue[sourceforge_DefaultFileTemplate]})"
    local _OS_List='';
    declare -g Request_JSON=''
    declare -g Request_Filename=''
    declare -g Request_OS_list=''

    for i in ${cfgValue[sourceforge_OS_List]}; do
        _OS_List="${_OS_List:+${_OS_List}&}default=${i}";
    done


#echo done; return
    printf "===================================================\n"
    printf "===================================================\n"
    printf "====   Updating Sourceforge Default link       ====\n"
    printf "====   for project %-25s   ====\n" "${cfgValue[sourceforge_Project]}"
    printf "===================================================\n"
    printf "===================================================\n\n"
    Request_JSON=`curl -s -H "Accept: application/json" -X PUT \
        -d "$_OS_List" \
        -d "api_key=${cfgValue[sourceforge_ApiKey]}" \
        "https://sourceforge.net/projects/${cfgValue[sourceforge_Project]}/files/$_DefaultFile"`
    ${DEBUG:-false} && {
        echo "\n==================================================="
        echo "==================================================="
        echo "====   Debug Output from updateSourceforge()   ===="
        echo "==================================================="
        echo "==================================================="
        jq . <<< "$Request_JSON"
        echo
    }
    Request_Filename=`jq -c .result.name <<< "$Request_JSON"`
    Request_OS_list=`jq -c .result.x_sf.default <<< "$Request_JSON"`
    printf "filename ='%s'\n" "$Request_Filename"
    printf "OS list  ='%s'\n" "$Request_OS_list"
    echo
}



RunAllUpdates() {
    getCurrentProjectInfo;
    updateSourceforge "$release_version";
}


main() {
    clear;
        cat <<-EOF
	     _________________________________________________
	    /________________________________________________/|
	    |                                               | |
	    |  Ready update the Sourceforge default link    | |
	    |      for project                              | |
	    |           *  $(printf "%-33s" "${cfgValue[sourceforge_Project]}";)| |
	    |                                               | |
	    |_______________________________________________|/


	EOF

    GetKey 'Yn' "Continue and Update Sourceforge Default Link?";
    if TestKey "Y"; then RunAllUpdates $Version $Date; fi

    echo
    echo
}

main;

exit;
