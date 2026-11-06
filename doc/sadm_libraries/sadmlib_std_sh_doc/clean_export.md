# clean_export_dir()
## Synopsys
`clean_export_dir [VMName] [export_directory]`
## Description
The [VMName] indicate the virtual machine name and the location of the export directory.
The value of '**SADM_VM_EXPORT_TO_KEEP**' field is define in the $SADMIN/cfg/sadmin.cfg file.
It indicate the number of export (date) to keep for the corresponding VM.
## Argument(s)
- [1] [vmName] (String)
       - Contain the name of the virtual machine to export.
- [2] [Export Dir. Name]  (String)
       - Specify the name of the export directory.
## Value returned
| Integer | Desciption                            |
|:-------:|:------------------------------------- |
| 1       | Error occured when doing the cleanup. |
| 0       | Cleanup was done with success.        |
## Example
```bash
Build NFS mount point with data from SADMIN configuration file.
LOCAL_DIR="/tmp/nfs.$$"
NFS_DIR="${SADM_VM_EXPORT_NFS_SERVER}:${SADM_VM_EXPORT_MOUNT_POINT}"
   
sudo mount "$NFS_DIR" "$LOCAL_DIR"
if [ "$?" -ne 0 ]                               # If Error during mount
    then sadm_write_err "[ ERROR ] mount $NFS_MOUNT $NFS_DIR"
         sudo umount "${NFS_DIR}" >/dev/null 2>&1  # Ensure Dest. Dir Unmounted
         return 1
    else sadm_write_log "[ OK ] NFS Mount worked."
fi  

clean_export_dir "$VM" "${NFS_DIR}/${VM}"
if [ "$?" -ne 0 ]
    then sadm_write_err "[ ERROR ] Error while doing the export cleanup."
    else sadm_write_log "[ OK ] Cleanup was done successfully."
fi
```
