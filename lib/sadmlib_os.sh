#!/usr/bin/env bash
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
# Run this function only when on RedHat, Alma, Rocky, CentOS
#===================================================================================================
add_epel_9_repo()
{

    case "$SADM_OSNAME" in 
        "REDHAT" )          printf "Enable $SADM_OSNAME 'codeready-builder' EPEL repository.\n" |tee -a $SLOG
                            printf "subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms " |tee -a $SLOG 
             subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'codeready-builder' EPEL repository." |tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi add_epel_7_repo 
        "ROCKY|ALMA" )      add_epel_7_repo 
        "CENTOS" )          add_epel_7_repo 
        "REDHAT" )          add_epel_7_repo 
    esac
    
    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then printf "Enable 'codeready-builder' EPEL repository for $SADM_OSNAME ...\n" |tee -a $SLOG
             printf "subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms " |tee -a $SLOG 
             subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'codeready-builder' EPEL repository." |tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
             
             printf "Enable 'codeready-builder' EPEL repository for $SADM_OSNAME ...\n" |tee -a $SLOG
             printf "subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms " |tee -a $SLOG 
             subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'codeready-builder' EPEL repository." |tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
        else printf "Enabling 'crb' repository for $SADM_OSNAME ...\n" |tee -a $SLOG
             printf "    - dnf config-manager --set-enabled crb " | tee -a $SLOG 
             dnf config-manager --set-enabled crb  >>$SLOG 2>&1 
             if [ $? -ne 0 ]
                then echo "[ ERROR ] Couldn't enable 'crb' repository." | tee -a $SLOG
                     return 1 
                else echo " [ OK ]" |tee -a $SLOG
             fi 
    fi 

    if [ "$SADM_OSNAME" = "ROCKY" ] || [ "$SADM_OSNAME" = "ALMA" ] 
        then dnf repolist | grep -q "^epel "
             if [ $? -ne 0 ] 
                then printf "\nInstalling epel-release on $SADM_OSNAME V9 ...\n" | tee -a $SLOG
                     printf "    - dnf -y install epel-release " | tee -a $SLOG
                     dnf -y install epel-release >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then echo "[Error] Adding epel-release V9 repository." |tee -a $SLOG
                             return 1 
                        else echo " [ OK ]" |tee -a $SLOG
                     fi
                else printf "\nRepository epel-release is already installed ...\n"  |tee -a $SLOG
             fi
             return 0 
    fi 

    if [ "$SADM_OSNAME" = "CENTOS" ] 
        then ins_count=0
             dnf repolist | grep -q "^epel " 
             if [ $? -ne 0 ] ; then ((ins_count++)) ; fi
             dnf repolist | grep -q "^epel-next "
             if [ $? -ne 0 ] ; then ((ins_count++)) ; fi
             if [ $ins_count -ne 0 ] 
                then printf "\nInstalling epel-release & epel-next-release on CentOS V9 ...\n" |tee -a $SLOG
                     printf "    - dnf -y install dnf install epel-release epel-next-release" |tee -a $SLOG
                     dnf -y install dnf install epel-release epel-next-release  >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then printf "[ ERROR ] Adding epel-release V9 repository.\n" |tee -a $SLOG
                             return 1 
                        else printf " [ OK ]\n" |tee -a $SLOG
                     fi
                else printf "\nRepositories epel-release & epel-next-release are already installed.\n" |tee -a $SLOG
             fi 
    fi  

    if [ "$SADM_OSNAME" = "REDHAT" ] 
        then printf "\nImport EPEL 9 GPG Key ...\n" |tee -a $SLOG
             printf "    - rpm --import http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9 " |tee -a $SLOG 
             rpm --import http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9
             if [ $? -ne 0 ]
                then printf "[ ERROR ] Importing epel-release V9 GPG Key.\n" |tee -a $SLOG
                     return 1 
                else printf "[ OK ]\n" |tee -a $SLOG
             fi
             dnf repolist | grep -q "^epel "
             if [ $? -ne 0 ] 
                then printf "\nInstalling epel-release CentOS/Redhat V9 ...\n" |tee -a $SLOG
                     printf "    - dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm " |tee -a $SLOG
                     dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm >>$SLOG 2>&1
                     if [ $? -ne 0 ]
                        then printf "[ ERROR ] Adding epel-release V9 repository.\n" |tee -a $SLOG
                             return 1 
                        else printf "[ OK ]\n" |tee -a $SLOG
                     fi
                else printf "\nRepository epel-release already installed.\n" |tee -a $SLOG
             fi 
    fi 
}



#===================================================================================================
# Install EPEL Repository on / Redhat / CentOS / Rocky / Alma 
# Install Fusion repository on Fedora 
#
#===================================================================================================
add_epel_repo()
{
    # If not Red Hat or CentOS, just return to caller 
    if [ "$OS_NAME" !=  "REDHAT" ] && [ "$OS_NAME" !=  "CENTOS" ] && [ "$OS_NAME" != "ALMALINUX" ] && [ "$OS_NAME" != "ROCKY" ]
        then write_log "No EPEL repository for $OS_NAME" 
             return 0 
    fi
    error_count=0

    #Add EPEL repository on Redhat, CentOS, Rocky and Alma Linux 
    if [ "$SADM_OS_NAME" = "REDHAT"] || [ "$SADM_OS_NAME" = "CENTOS" ] \
       [ "$SADM_OS_NAME" = "ROCKY"]  || [ "$SADM_OS_NAME" = "ALMA" ] 
       then case "$SADM_OS_MAJORVER" in 
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

    fi 

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
