#!/usr/bin/env bash

###### WORK IN PROGRESS DO NOT USE ########



#===================================================================================================
#  Author:    Jacques Duplessis
#  Title      sadmlib_os.sh
#  Date:      December 2023
#  Synopsis:  O/S related Shell Library
#
# --------------------------------------------------------------------------------------------------
# Description
# This file is not a stand-alone shell script; it provides functions to your scripts that source it.
#
# Note : All scripts (Shell,Python,Php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments generally begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
#@2023_12_24 v0.1 Initial working version
#
# --------------------------------------------------------------------------------------------------





# --------------------------------------------------------------------------------------------------
# L O C A L    V A R I A B L E S    
# --------------------------------------------------------------------------------------------------
#
export sadmlib_os_ver=0.1                                               # This Library Version



#===================================================================================================
#  Install EPEL 7 Repository for Redhat / CentOS / Rocky / Alma Linux / 
#===================================================================================================
add_epel_7_repo()
{

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then rep1=' --enable rhel-*-optional-rpms'
             rep2=' --enable rhel-*-extras-rpms'
             rep3=' --enable rhel-ha-for-rhel-*-server-rpms'
             printf "subscription-manager repos $rep1 $rep2 $rep3"
             subscription-manager repos $rep1 $rep2 $rep3 >>$SLOG 2>&1
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable EPEL repositories." |tee -a $SLOG
                     return 1 
                else echo "[ OK ]" |tee -a $SLOG
             fi 
        else printf "Enable 'yum install epel-release' repository ...\n" |tee -a $SLOG
             printf "    - yum install epel-release " | tee -a $SLOG 
             yum install epel-release   >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'epel-release' repository." | tee -a $SLOG
                     return 1 
                else echo "[ OK ]" |tee -a $SLOG
                     return 0                                           # CentOS nothing more to do
             fi 
    fi 

    if [ ! -r /etc/yum.repos.d/epel.repo ]  
       then printf "Adding CentOS/Redhat V7 EPEL repository ...\n" |tee -a $SLOG
            printf "yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm\n" >>$SLOG 2>&1
            yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm >>$SLOG 2>&1
            if [ $? -ne 0 ]
                then echo "[ ERROR ] Adding EPEL 7 repository." |tee -a $SLOG
                     return 1
            fi
            #printf "Disabling EPEL Repository (yum-config-manager --disable epel) " |tee -a $SLOG
            #yum-config-manager --disable epel >/dev/null 2>&1
            #if [ $? -ne 0 ]
            #   then echo "Couldn't disable EPEL 7 for version $W_OSVERSION" | tee -a $SLOG
            #        return 1
            #   else echo "[ OK ]"
            #fi 
            return 0
    fi
}


#===================================================================================================
# Add EPEL Repository on Redhat / CentOS 8 (but do not enable it)
#===================================================================================================
add_epel_8_repo()
{

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then printf "Enable 'codeready-builder' EPEL repository ...\n" |tee -a $SLOG
             printf "subscription-manager repos --enable codeready-builder-for-rhel-8-$(arch)-rpms " |tee -a $SLOG 
             subscription-manager repos --enable codeready-builder-for-rhel-8-$(arch)-rpms >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'codeready-builder' EPEL repository." |tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
        else printf "Enable 'powertools' repository ...\n" |tee -a $SLOG
             printf "    - dnf config-manager --set-enabled powertools " | tee -a $SLOG 
             dnf config-manager --set-enabled powertools   >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'powertools' repository." | tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
    fi 

    if [ "$SADM_OSNAME" = "REDHAT" ] 
       then printf "dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm\n" >>$SLOG 2>&1
            dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm >>$SLOG 2>&1
            if [ $? -ne 0 ]
               then echo "[ WARNING ] Couldn't enable EPEL 8 repository" |tee -a $SLOG
                    return 1
               else echo "[ OK ]" |tee -a $SLOG
            fi 
    fi

    if [ "$SADM_OSNAME" = "CENTOS" ] 
       then printf "dnf -y install dnf install epel-release epel-next-release\n"  >>$SLOG 2>&1
            dnf -y install dnf install epel-release epel-next-release >>$SLOG 2>&1 
            if [ $? -ne 0 ]
               then echo "[ WARNING ] Couldn't enable EPEL 8 repositories" |tee -a $SLOG
                    return 1
               else echo "[ OK ] Enable EPEL 8 repositories" |tee -a $SLOG
            fi 
    fi

    if [ "$SADM_OSNAME" = "ALMA" ] || [ "$SADM_OSNAME" = "ROCKY" ]
       then printf "dnf -y install epel-release"
            dnf -y install epel-release >>$SLOG 2>&1 
            if [ $? -ne 0 ]
               then echo "[ WARNING ] Couldn't enable EPEL 8 repository" |tee -a $SLOG
                    return 1
               else echo "Enable EPEL 8 repository [ OK ]" |tee -a $SLOG
            fi 
    fi

    #printf "Disabling EPEL Repository (yum-config-manager --disable epel) " |tee -a $SLOG
    #dnf config-manager --disable epel >/dev/null 2>&1
    #if [ $? -ne 0 ]
    #   then echo "Couldn't disable EPEL for version $W_OSVERSION" | tee -a $SLOG
    #        return 1
    #   else echo "[ OK ]" |tee -a $SLOG
    #fi 
}


#===================================================================================================
# Add EPEL Repository on Redhat / CentOS 9 (but do not enable it)
#===================================================================================================
add_epel_9_repo()
{

    case "$SADM_OS_NAME" in 

        "ROCKY" | "ALMA" | "CENTOS" )

            # Install 'crb' (Code Ready Builder) 
             dnf repolist enabled | grep -q "^crd "                     # Check crb already enable
             if [ $? -ne 0 ]                                            # If not enable
                then write_log "Enable 'crb' EPEL repository on $OS_NAME ..."
                     dnf config-manager --set-enabled crb 
                     if [ $? -ne 0 ]
                        then write_err "[ ERROR ] Couldn't enable 'crb' repository."
                             return 1 
                        else write_log "[ OK ] Repository 'crb' is now enable."
                     fi
                else write_log "Repository 'crb' already enable."
             fi 
             
            # Install epel repository 
            dnf repolist enabled | grep -q "^epel "                    # Check epel already enable
            if [ $? -ne 0 ]  
                then write_log "Install epel-release on $OS_NAME v${SADM_OS_VERSION} ..." 
                     dnf -y install epel-release
                     if [ $? -ne 0 ]
                        then write_err "[ ERROR ] Adding epel-release v${SADM_OS_VERSION} repository."
                             return 1 
                        else write_log "[ OK ] Repository 'epel-release' v${SADM_OS_VERSION} is now enable."
                             dnf config-manager --enable epel
                     fi
                else write_log "Repository 'epel' v${SADM_OS_VERSION} already enable."
            fi
            ;;

        # Install epel-next repository only on CentOS 
        "CENTOS" ) 
                dnf repolist enabled | grep -q "^epel-next "               # epel-next already enable?
                if [ $? -ne 0 ]  
                   then write_log "Install epel-next-release on $OS_NAME v${SADM_OS_VERSION} ..." 
                        dnf -y install epel-next-release
                        if [ $? -ne 0 ]
                           then write_err "[ ERROR ] Adding 'epel-next' v${SADM_OS_VERSION} repository."
                                return 1 
                           else write_log "[ OK ] Repository 'epel-next' v${SADM_OS_VERSION} is now enable."
                        fi
                        dnf config-manager --enable epel-next              # Make sure it's enable
                   else write_log "Repository 'epel-next' v${SADM_OS_VERSION} already enable."
                fi
                return 0 
                ;;

        # Install codeready-builder & epel-release-latest repositories
        "REDHAT" ) 
                dnf repolist enabled | grep -q "^codeready-builder-for-rhel-9" # Repo already configure
                if [ $? -ne 0 ]  
                   then subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms >>$SLOG 2>&1 
                        if [ $? -ne 0 ]
                           then write_err "[ ERROR ] Subscribing to 'codeready-builder-for-rhel-9-$(arch)-rpms'."
                                return 1 
                           else write_log "[ OK ] Repository 'codeready-builder-for-rhel-9-$(arch)-rpms' is now enable."
                        fi
                   else write_log "[ OK ] Repository 'codeready-builder-for-rhel-9-$(arch)-rpms' is already installed."
                        return 0

                dnf repolist enabled | grep -q "^rhel-9-for-x86_64-baseos" # Repo already configure
                if [ $? -ne 0 ]  
                   then write_log "Installing 'epel-release-latest-9.noarch.rpm' CentOS/Redhat v9 ..." 
                        dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm >>$SLOG 2>&1
                        if [ $? -ne 0 ]
                           then write_err "[ ERROR ] Adding 'epel-release-latest-9.noarch.rpm' v9 repository."
                                return 1 
                           else write_log"[ OK ] Repository 'rhel-9-for-x86_64-baseos' installed." 
                        fi
                   else write_log "Repository 'rhel-9-for-x86_64-baseos' is already enable."
                fi
                ;;
    esac
    return 0
}



#===================================================================================================
# Install EPEL Repository on / Redhat / CentOS / Rocky / Alma 
# Install Fusion repository on Fedora 
#
#===================================================================================================
add_epel_repo()
{
    # If not Red Hat or CentOS, just return to caller 
    if [ "$OS_NAME" != "REDHAT" ] && [ "$OS_NAME" != "CENTOS" ] && \
       [ "$OS_NAME" != "ALMA"   ] && [ "$OS_NAME" != "ROCKY"  ]
        then write_log "No EPEL repository for '$OS_NAME'." 
             return 1
    fi
    error_count=0

    #Add EPEL repository on Redhat, CentOS, Rocky and Alma Linux 
    case "$SADM_OS_MAJORVER" in 
                7)  add_epel_7_repo 
                    if [ $? -ne 0 ]
                        then sadm_write_err "[Error] Adding EPEL $W_OSVERSION repository." 
                             ((error_count++))
                             break
                    fi
                    ;;
                8)  add_epel_8_repo 
                    if [ $? -ne 0 ]
                        then sadm_write_err "[Error] Adding EPEL $W_OSVERSION repository."
                             ((error_count++))
                             break
                    fi
                    ;;
                9)  add_epel_9_repo 
                    if [ $? -ne 0 ]
                        then sadm_write_err "[Error] Adding EPEL $W_OSVERSION repository."
                             ((error_count++))
                             break
                    fi
                    ;;
                *)  sadm_write_err "[Error] EPEL $W_OSVERSION is not supported yet."
                    ((error_count++))
                    break
                    ;;
            esac

    # On Fedora install rpmfusion repositories (free and non-free release)
    if [ "$SADM_OS_NAME" = "FEDORA"] 
        then dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
             if [ $? -ne 0 ]
                 then sadm_write_err "[Error] Adding EPEL $W_OSVERSION repository."
                      ((error_count++))
                      break
             fi
             dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
             if [ $? -ne 0 ]
                 then sadm_write_err "[Error] Adding EPEL $W_OSVERSION repository."
                      ((error_count++))
                      break
             fi
    fi 

    return "$error_count"
}





# --------------------------------------------------------------------------------------------------
# Things to do when first called
# --------------------------------------------------------------------------------------------------
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]                              # Library invoke directly
        then printf "$(date "+%C%y.%m.%d %H:%M:%S") Starting ...\n"     # Show reference point #1
    fi
