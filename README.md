# symlink_create.sh
BASH script to create / update a symbolic link to a folder using a primary and secondary source.

This script is supposed to be run at boot (by cron) or as a scheduled maintenance script to create and update a symbolic link pointing to a specific directory.

The script checks if a "primary" folder (to be linked) is available and then creates the symbolic link (with the desired location and name) pointing to it. It then tests the symbolic link's read-write availability.

If the primary folder is not available (e.g. a hard disk was not mounted properly at boot) the script creates the symbolick link using a "secondary" folder.

The original usage is to create a certain path for TV recordings on a system that has an external drive that might not be available (if the drive is disconnected or the mounting fails when booting). In this case the same symbolic link is created for a folder that is known (!) to be available, for example a freely shared folder inside the user home directory. 

You should check that the primary folder is available by creating proper mounting rules in fstab (in case of an external hard drive). Also the script was not planned to check user privileges. You should make sure that the directories are available with sufficient rights for the user who executes the script.
