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

x() {
    cat <<EOF
        <ehuelsmann> although, if you could automate:
        <ehuelsmann> 1. update wikipedia entries        DONE
        <ehuelsmann> 2. update IRC title                DONE
        <ehuelsmann> 3. post to ledgersmb.org
        <ehuelsmann> 4. update the SF download link     In Progress
        <ehuelsmann> and 5. Post to the mailing lists   DONE
        <ehuelsmann> then you're my man! :-)
EOF
}


getChangelogEntry() {
    :
}


createEmail() {
    #HTML email is possible. Just add these lines after the subject:
    #Mime-Version: 1.0
    #Content-type: text/html; charset=”iso-8859-1″
    cat <<-EOF >/tmp/msg.txt
	To: $1
	From: ${cfgValue[mail_FromAddress]}
	Subject: LedgerSMB $release_version released
	
	The LedgerSMB development team is happy to announce yet another new
	version of its open source ERP and accounting application. This release
	contains the following fixes and improvements:
	
	$extracted_changelog
	
	The release can be downloaded from sourceforge at
	  https://sourceforge.net/projects/ledger-smb/files/$prj_url_dir/$release_version/
	
	These are the sha256 checksums of the uploaded files:
	$extracted_sha256sums
	
EOF
    $Editor /tmp/msg.txt
    GetKey "Yn" "Send email Now? "
    if TestKey "y"; then return `true`; else return `false`; fi
}

SelectEditor() {
    [[ -z $Editor ]] && Editor=`which $EDITOR`
    [[ -z $Editor ]] && Editor=`which $VISUAL`
    [[ -z $Editor ]] && Editor=`which mcedit`
    [[ -z $Editor ]] && Editor=`which nano`
    [[ -z $Editor ]] && Editor=`which pico`
    [[ -z $Editor ]] && Editor=`which vi`
    [[ -z $Editor ]] && Editor=`which less`
    [[ -z $Editor ]] && Editor="$(which more); read -n -p'Press Enter to Continue';"
    [[ -z $Editor ]] && Editor="$(which cat); read -n -p'Press Enter to Continue';"
}

sendEmail() {
    Sender=${EMAIL};
    [[ -n $EMAIL ]] && scrape_config_files_for_Sender;

    MTA="${cfgValue[mail_MTAbinary]}";
    [[ -z $MTA ]] && MTA=`which ssmtp`;
    [[ -z $MTA ]] && MTA=`which sendmail`;
    [[ -x `which $MTA` ]] || { echo "Exiting: No Known MTA"; exit 1; }
#    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
#    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
#    echo '%%                                     %%';
#    echo '%%  No Email Sent.Function incomplete  %%';
#    echo '%%                                     %%';
#    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
#    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
#return;
    if createEmail "${cfgValue[mail_AnnounceList]}"; then
        $MTA "${cfgValue[mail_FromAddress]}" < msg.txt
    fi

    if createEmail "${cfgValue[mail_UsersList]}"; then
        $MTA "${cfgValue[mail_FromAddress]}" < msg.txt
    fi

    if createEmail "${cfgValue[mail_DevelList]}"; then
        $MTA "${cfgValue[mail_FromAddress]}" < msg.txt
    fi
}

#### "${cfgValue[_]}"
updateWikipedia() { # $1 = New Version     $2 = New Date
    # wikipedia-update.pl [boilerplate|Wikipage] [stable|preview] [NewVersion] [NewDate] [UserName Password]
    ./release-wikipedia.pl "${cfgValue[wiki_PageToEdit]}" "$release_type" "$1" "$2" "${cfgValue[wiki_User]}" "${cfgValue[wiki_Password]}"
}

updateIRC() {
    ./release-irc.sh $release_type $release_version
}

updateSourceforge() {  # note release-sourceforge.sh silently exits if $release_type != stable .   Anything else doesn't make sense.
    ./release-sourceforge.sh "$release_type" "$release_version"
}

RunAllUpdates() {
    if ! [[ "$release_type" == "old" ]]; then
        updateWikipedia "$release_version" "$release_date";
        updateIRC;
        updateSourceforge;
    fi
    sendEmail;
}


ValidateEnvironment() {
    ############
    #  Select an editor. (function is in bash-lib.sh
    ############
        SelectEditor;

    ############
    #  Test Config to make sure we have everything we need
    ############
        while true; do
            TestConfigInit;
            TestConfig4Key 'mail'   'AnnounceList'  'ledger-smb-announce@lists.sourceforge.net'
            TestConfig4Key 'mail'   'UsersList'     'ledger-smb-users@lists.sourceforge.net'
            TestConfig4Key 'mail'   'DevelList'     'ledger-smb-devel@lists.sourceforge.net'
            TestConfig4Key 'mail'   'FromAddress'   'release@ledgersmb.org'
#            TestConfig4Key 'mail'   'Password'      ''
            TestConfig4Key 'mail'   'MTAbinary'     'ssmtp'
            if TestConfigAsk "Send List Mail"; then break; fi
        done

        while true; do
            TestConfigInit;
            TestConfig4Key 'wiki'   'PageToEdit'    'Wikipedia:Sandbox'
            TestConfig4Key 'wiki'   'User'          'foobar'
            TestConfig4Key 'wiki'   'Password'      ''
            if TestConfigAsk "Wikipedia Version Update"; then break; fi
        done

        while true; do
            TestConfigInit;
            TestConfig4Key 'drupal' 'URL'           'www.ledgersmb.org'
            TestConfig4Key 'drupal' 'User'          'foobar'
            TestConfig4Key 'drupal' 'Password'      ''
            if TestConfigAsk "ledgersmb.org Release Post"; then break; fi
        done

        while true; do
            TestConfigInit;
            TestConfig4Key 'sourceforge' 'ApiKey'   ''
            TestConfig4Key 'sourceforge' 'Project'  'ledger-smb'
            if TestConfigAsk "Sourceforge Default Download Update"; then break; fi
        done

        while true; do # the script release-IRC.sh checks its own config. but lets at least make sure we have a server url
            TestConfigInit;
            TestConfig4Key 'irc' 'Server' 'chat.freenode.net';
            if TestConfigAsk "IRC Topic Update"; then break; fi
        done

    ############
    #  Test Environment to make sure we have everything we need
    ############
        local _envGOOD=true;
        [[ -z $release_version ]] && { _envGOOD=false; echo "release_version is unavailable"; }
        [[ -z $release_date    ]] && { _envGOOD=false; echo "release_date is unavailable"; }
        [[ -z $release_type    ]] && { _envGOOD=false; echo "release_type is unavailable"; } # one of stable | preview
        [[ -z $release_branch  ]] && { _envGOOD=false; echo "release_branch is unavailable"; } # describes the ????
        $_envGOOD || exit 1;
}


main() {
    clear;
        cat <<-EOF
	     ___________________________________________________________
	    /__________________________________________________________/|
	    |                                                         | |
	    |  Ready to send some updates out to the world            | |
	    |                                                         | |
	    |   *  Update Version on Wikipedia (en)                   | |
	    |   *  Update IRC Title                                   | |
	    |   *  Update Sourceforge Download Link                   | |
	    |   *  Send Release Emails to                             | |
	    |           *  $(printf "%-43s" "${cfgValue[mail_AnnounceList]}";)| |
	    |           *  $(printf "%-43s" "${cfgValue[mail_UsersList]}";)| |
	    |           *  $(printf "%-43s" "${cfgValue[mail_DevelList]}";)| |
	    |                                                         | |
	    |   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    | |
	    |      The following are not yet complete                 | |
	    |                                                         | |
	    |   *  Post to $(printf "%-43s" "${cfgValue[drupal_URL]}";)| |
	    |      Don't forget to use the 'release'                  | |
	    |      content type, and set the correct branch           | |
	    |      to $( printf "%-46s" "${release_branch:-*** Need to add this info ***}";)  | |
	    |        http://ledgersmb.org/node/add/release            | |
	    |                                                         | |
	    |   * Publish a release on GitHub                         | |
	    |         by converting the tag                           | |
	    |                                                         | |
	    |_________________________________________________________|/


	EOF

    ValidateEnvironment;

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





