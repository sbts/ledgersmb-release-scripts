#!/bin/bash

#ehuelsmann: did you have a chance to look at the printer config demo?
#http://tombuntu.com/index.php/2008/10/21/sending-email-from-your-system-with-ssmtp/

# import some functions that we need, like reading values from our config file.
#[ -f release-lib.sh ] && . release-lib.sh;
ConfigFile=~/.lsmb-release

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

#safe_source ./release-lib.sh

HowToGetAPIkey() {
    cat <<-EOF
	Here is how to get your API key:
	
	    Go to your account page.
	    Click on the "Generate" button under the Releases API Key.
	    Copy and paste the key that appears into 
	        ~/.lsmb-release
	            [sourceforge]
	            ApiKey    = YourKey
	
EOF
    GetKey 'yN' 'Continue with remaining tasks? '
    echo $Key asdf asdf asdf
    if TestKey "Y"; then : ; else exit 1; fi
}

#### "${cfgValue[_]}"
updateSourceforge() { # $1 = New Version     $2 = New Date
    #https://sourceforge.net/p/forge/community-docs/Using%20the%20Release%20API/
    #https://sourceforge.net/p/forge/documentation/Allura%20API/
    if ( [[ ! -v cfgValue[sourceforge_ApiKey] ]] || [[ -z "${cfgValue[sourceforge_ApiKey]}" ]] ); then HowToGetAPIkey; fi #return; fi
#    if [[ ! -v cfgValue[zsourceforge_ApiKey] ]]; then HowToGetAPIkey; fi
#    if [[ -z "${cfgValue[sourceforge_ApiKey]}" ]]; then HowToGetAPIkey; fi
    echo "key entry='${cfgValue[sourceforge_ApiKey]}'"
echo done; return
    curl -H "Accept: application/json" -X PUT \
        -d "default=windows&default=mac&default=linux&default=bsd&default=solaris&default=others" \
        -d "api_key=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
        https://sourceforge.net/projects/[PROJECT NAME]/files/[FILE PATH]



    # wikipedia-update.pl [boilerplate|Wikipage] [stable|preview] [NewVersion] [NewDate] [UserName Password]
    release-wikipedia.pl "${cfgValue[wiki_PageToEdit]}" "stable" "$1" "$2" "${cfgValue[wiki_User]}" "${cfgValue[wiki_Password]}"
}



RunAllUpdates() {
    updateSourceforge "$release_version" "$release_date";
}

RunAllUpdates
echo Continuing....
exit
main() {
        cat <<-EOF
	     _________________________________________________
	    /________________________________________________/|
	    |                                               | |
	    |  Ready to send some updates out to the world  | |
	    |                                               | |
	    |   *  Update Version on Wikipedia (en)         | |
	    |   *  Send Release Emails to                   | |
	    |           *  $(printf "%-33s" "${cfgValue[mail_AnnounceList]}";)| |
	    |           *  $(printf "%-33s" "${cfgValue[mail_UsersList]}";)| |
	    |           *  $(printf "%-33s" "${cfgValue[mail_DevelList]}";)| |
	    |                                               | |
	    |   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    | |
	    |      The following are not yet complete       | |
	    |                                               | |
	    |   *  Update version on Wikipedia (es)         | |
	    |        https://es.wikipedia.org/w/index.php?title=LedgerSMB&action=edit
	    |   *  Post to $(printf "%-33s" "${cfgValue[drupal_URL]}";)| |
	    |      Don't forget to use the 'release'        | |
	    |      content type, and set the correct branch | |
	    |      to '$branch'                             | |
	    |        http://ledgersmb.org/node/add/release  | |
	    |   *  Update IRC Title                         | |
	    |   *  Update Sourceforge Download Link         | |
	    |                                               | |
	    |   * Publish a release on GitHub               | |
	    |         by converting the tag                 | |
	    |                                               | |
	    |_______________________________________________|/


	EOF

    GetKey 'Yn' "Continue and send Updates to the world";
    if TestKey "Y"; then RunAllUpdates $Version $Date; fi

    echo
    echo
}

main;

exit;


#### everything below here is just notes. it can be removed without problems
+++++++++++++++++++++++++++++++++++
++++        cfgValue[@]        ++++
+++++++++++++++++++++++++++++++++++
key: drupal_Password     = 
key: drupal_URL          = www.ledgersmb.org
key: drupal_User         = *****
key: mail_FromAddress    = *******@******
key: mail_AnnounceList   = ledger-smb-announce@lists.sourceforge.net
key: mail_UsersList      = ledger-smb-users@lists.sourceforge.net
key: mail_DevelList      = ledger-smb-devel@lists.sourceforge.net
key: mail_Password       = testPW
key: wiki_PageToEdit     = User:Sbts.david/sandbox
key: wiki_Password       =
key: wiki_User           = ledgersmb_bot
+++++++++++++++++++++++++++++++++++



dcg_> ehuelsmann: so that is the link that you want the script to update? Do you have a procedure you follow to.update.it manually
<ehuelsmann> yes.
<ehuelsmann> if you go to the file/directory to be marked,
<ehuelsmann> then click on the (i) icon
<ehuelsmann> hmm. that's an i
<ehuelsmann> you'll see a list of platforms
<ehuelsmann> each of those platforms can be checked independently.
<ehuelsmann> because we don't distribute binaries, I check them all for the same directory.
<ehuelsmann> then, in 2 minutes or so,
<ehuelsmann> the link on the pages updates.
<ehuelsmann> is that what you wanted to know?
<ehuelsmann> oh. you need to confirm with "ok", I think.
<ehuelsmann> "Save" to be exact
<dcg_> Yep thanks. If I know the manual process I can validate the automation a bit easier

