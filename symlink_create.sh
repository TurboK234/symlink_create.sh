#!/bin/bash
# This script is supposed to be run at boot (by cron) or as a scheduled
# maintenance script to create and update a symbolic link pointing to a
# specific directory.
# .
# The script checks if a "primary" folder (to be linked) is available
# and then creates the symbolic link (with the desired location and name)
# pointing to it. It then tests the symbolic link's read-write availability.
# .
# If the primary folder is not available (e.g. a hard disk was not
# mounted properly at boot the script creates the symbolick link
# using a "secondary" folder.
# .
# The original usage is to create a certain path for TV recordings
# on a system that has an external drive that might not be available
# (if the drive is disconnected or the mounting fails when booting).
# In this case the same symbolic link is created for a folder that
# is known (!) to be available, for example a freely shared folder inside
# the user home directory. 
# .
# You should check that the primary folder is available by creating proper
# mounting rules in fstab (in case of an external hard drive). Also
# the script was not planned to check user privileges. You should
# make sure that the directories are available with sufficient rights
# for the user who executes the script.

# Set up the directory (without the last slash) in which the script (and the log) is (please check the permissions).
scriptdir="/home/user/utilities"

# Set up the (primary) source directory for the symbolic link (without the last slash).
primarydir="/media/theprimarydrive"

# Set up the (secondary) source directory for the symbolic link if the primary directory fails in read-write test (without the last slash).
secondarydir="/home/user/thebackupfolder"

# Set up the symbolic link location and name (without the last slash).
symlinklocation="/media/symlink_folder"


# No need to edit the lines below this point, do not touch!

errorlvl=0
sourcesuccess=0

# Check that the script directory is valid.
if [ -d "$scriptdir" ]
then
    # This is the expected and not-logged condition.
    echo "The script directory seems to exist (permissions presumed), continuing."
else
    echo "The script directory is not set or it is not valid, exiting... (no log was created)"
    sleep 2
    exit 0
fi

# Script initiation logging, this can be commented out.
curdatetime=$(date +"%d/%m/%Y %R")
echo "$curdatetime : Executing the symlink creation script." >> "$scriptdir/log_symlink_create.txt"

# Next, the write-read-accessibility of the primary folder is tested
# by creating a probe file. A numeric value is then written and then
# the value is read to a variable. If the variable matches the expected
# value, the target folder is considered valid. The probe file is deleted
# immediately after the the value is read.

# First, delete the unlikely pre-existing probe file.
if [ -f "$primarydir"/dirwritereadtest.txt ]
then
    rm "$primarydir"/dirwritereadtest.txt
fi

# If the file can't be deleted, the permission test fails.
if [ -f "$primarydir"/dirwritereadtest.txt ]
then
    errorlvl=1
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : There was a probe file that could not be deleted." >> "$scriptdir/log_symlink_create.txt"
    echo "The primary folder read-write test failed (check permissions), checking secondary folder next."
fi

if [ "$errorlvl" -lt 1 ]
then
    # Next create a the probe file.
    touch "$primarydir"/dirwritereadtest.txt

    # Check that the probe file was created, otherwise try remounting and re-touching.
    if [ -f "$primarydir"/dirwritereadtest.txt ]
    then
        # This is the expected case, and the file was created, no logging.
        echo "The probe file was created, continuing."
    else
        curdatetime=$(date +"%d/%m/%Y %R")
        echo "$curdatetime : Could not write a file in the $primarydir folder, trying to remount." >> "$scriptdir/log_symlink_create.txt"
        sudo mount -a
        sleep 5
        touch "$primarydir"/dirwritereadtest.txt
    fi

    # And now check that the file is there, otherwise primary folder fails.
    if [ -f "$primarydir"/dirwritereadtest.txt ]
    then
        # This is still the expected case.
        echo "Double-check passed, continuing."
    else
		    errorlvl=1
        curdatetime=$(date +"%d/%m/%Y %R")
        echo "$curdatetime : The probe file could not be created in the $primarydir folder, primary will most likely fail." >> "$scriptdir/log_symlink_create.txt"
        echo "The primary folder write-read permissions test failed, check the log."
    fi

    sleep 1
    echo "2" >> "$primarydir"/dirwritereadtest.txt
    sleep 1
    primarytestread=$(<"$primarydir/dirwritereadtest.txt")
    rm "$primarydir"/dirwritereadtest.txt

    if [ "$primarytestread" != 2 ]
    then
        errorlvl=1
        curdatetime=$(date +"%d/%m/%Y %R")
        echo "$curdatetime : The write-read test for $primarydir failed. Check that the folder is valid and all users have write permissions." >> "$scriptdir/log_symlink_create.txt"
    else
        sourcesuccess=1
		    curdatetime=$(date +"%d/%m/%Y %R")
        echo "$curdatetime : The write-read test for $primarydir succeeded." >> "$scriptdir/log_symlink_create.txt"
	      echo "Next, create the symbolic link."
    fi
fi

# Next, the write-read-accessibility of the secondary folder is tested
# in the same manner as the primary folder, but only if the primary folder failed.

if [ "$sourcesuccess" != 1 ]
then
    # First, delete the unlikely pre-existing probe file.
    if [ -f "$secondarydir"/dirwritereadtest.txt ]
    then
        rm "$secondarydir"/dirwritereadtest.txt
    fi

    # If the file can't be deleted, the permission test fails.
    if [ -f "$secondarydir"/dirwritereadtest.txt ]
    then
        errorlvl=2
        curdatetime=$(date +"%d/%m/%Y %R")
        echo "$curdatetime : There was a probe file that could not be deleted." >> "$scriptdir/log_symlink_create.txt"
        echo "The secondary folder read-write test failed (check permissions), check the log (no symbolic links will be created or updated)."
    fi

    if [ "$errorlvl" -lt 2 ]
    then
        # Next create a the probe file.
        touch "$secondarydir"/dirwritereadtest.txt

        # Check that the probe file was created, otherwise try remounting and re-touching.
        if [ -f "$secondarydir"/dirwritereadtest.txt ]
        then
            # This is the expected case, and the file was created, no logging.
            echo "The probe file was created, continuing."
        else
            curdatetime=$(date +"%d/%m/%Y %R")
            echo "$curdatetime : Could not write a file in the $secondarydir folder, trying to remount." >> "$scriptdir/log_symlink_create.txt"
            sudo mount -a
            sleep 5
            touch "$secondarydir"/dirwritereadtest.txt
        fi

        # And now check that the file is there, otherwise.
        if [ -f "$secondarydir"/dirwritereadtest.txt ]
        then
            # This is still the expected case.
            echo "Double-check passed, continuing."
        else
            curdatetime=$(date +"%d/%m/%Y %R")
            echo "$curdatetime : The probe file could not be created in the $secondarydir folder, secondary will most likely fail." >> "$scriptdir/log_symlink_create.txt"
            echo "The secondary folder write-read permissions test failed, check the log."
        fi

        sleep 1
        echo "2" >> "$secondarydir"/dirwritereadtest.txt
        sleep 1
        secondarytestread=$(<"$secondarydir/dirwritereadtest.txt")
        rm "$secondarydir"/dirwritereadtest.txt

        if [ "$secondarytestread" != 2 ]
        then
            errorlvl=2
            curdatetime=$(date +"%d/%m/%Y %R")
            echo "$curdatetime : The write-read test for $secondarydir failed. Check that the folder is valid and all users have write permissions." >> "$scriptdir/log_symlink_create.txt"
            echo "Next, log the error and exit, no symbolic links will be created or updated."
        else
            sourcesuccess=2
			      curdatetime=$(date +"%d/%m/%Y %R")
	          echo "$curdatetime : The write-read test for $secondarydir succeeded." >> "$scriptdir/log_symlink_create.txt"
            echo "Next, create the symbolic link."
        fi
    fi
fi

# Next create symbolic link according to the previous tests (either for primary or secondary directory if succeeded, fail if not).

sleep 1

if [ "$sourcesuccess" -lt 1 ]
then
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : Both primary and secondary directories failed their read-write tests, exiting." >> "$scriptdir/log_symlink_create.txt"
    echo "Both primary and secondary directories failed their read-write tests, exiting."
  	exit 0
fi

if [ "$sourcesuccess" = 1 ]
then
    sudo ln -sfn "$primarydir" "$symlinklocation"
    sleep 1
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : Symlink created for $primarydir." >> "$scriptdir/log_symlink_create.txt"
    echo "Symlink created for $primarydir."
fi

if [ "$sourcesuccess" = 2 ]
then
    sudo ln -sfn "$secondarydir" "$symlinklocation"
    sleep 1
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : Symlink created for $secondarydir (primary had failed)." >> "$scriptdir/log_symlink_create.txt"
    echo "Symlink created for $secondarydir."
fi

# Finally test that the symbolic link is a folder and the read-write test works for it.

if [ -d "$symlinklocation" ]
then
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : Symlink in $symlinklocation is a folder, continuing." >> "$scriptdir/log_symlink_create.txt"
    echo "Symlink in $symlinklocation is a folder, continuing."
else
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : Symlink in $symlinklocation is not a folder, unexpected failure. Exiting." >> "$scriptdir/log_symlink_create.txt"
    echo "Symlink is not a folder, unexpected failure, check the log. Exiting."
    exit 0
fi

# Next create a the probe file in the symlink location.
touch "$symlinklocation"/dirwritereadtest.txt

# Check that the probe file was created, otherwise try remounting and re-touching.
if [ -f "$symlinklocation"/dirwritereadtest.txt ]
then
    # This is the expected case, and the file was created, no logging.
    echo "The probe file was created, continuing."
else
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : Could not write a file in the $symlinklocation folder. Exiting." >> "$scriptdir/log_symlink_create.txt"
    echo "Could not write a file in the $symlinklocation folder. Check the log. Exiting."
fi

sleep 1
echo "2" >> "$symlinklocation"/dirwritereadtest.txt
sleep 1
symlinktestread=$(<"$symlinklocation/dirwritereadtest.txt")
rm "$symlinklocation"/dirwritereadtest.txt

if [ "$symlinktestread" != 2 ]
then
    errorlvl=3
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : The write-read test for $symlinklocation failed. This was the final test that failed. Exiting." >> "$scriptdir/log_symlink_create.txt"
    echo "The write-read test for $symlinklocation failed. This was the final test that failed. Check the log. Exiting."
    exit 0
else
    symlinksuccess=1
    curdatetime=$(date +"%d/%m/%Y %R")
    echo "$curdatetime : The write-read test for $symlinklocation succeeded. Exiting the script." >> "$scriptdir/log_symlink_create.txt"
    echo "The write-read test for $symlinklocation succeeded. Exiting."
fi

exit 0
