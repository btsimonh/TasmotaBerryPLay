# Timelapse/Motion using Berry in Tasmota

## Intent

A single berry scripts which should do suit the majority of use cases for timelpase and motion detected images using esp32cam and Tasmota.

On first run, default control files `/motion.json` and `/timelapse` will be created int he rott of flash.


folder control file `<root>/<currfolder>/config.json`

Stores information about the content of the current folder.  Used by folder display html/js to know when additional frames are available.

like:
```
{
    "frame":300,
    "firstframe":125
}
```

These files will be updated with the current folder every time it changes.

This is to record timelapse images to folders on an attached SD card.

The time interval is specified using either an interval in ms, or as a Cron time specification.

The images stored to the folder are accompanied by a json per image containing some metadata, as well as a folder json which contains information about the folder.

The script should create a new folder at certain points.  These points are specified in terms of a cron string.

The script should 'pick up where it left off' after a restart.


## Preparing your esp32cam

For easy access to the results of saving images, merge this [PR](https://github.com/arendst/Tasmota/pull/18859) into your branch, and `#define UFILESYS_STATIC_SERVING`

load camdriver.be

First run will create /sd/timelapse/
Put `index.html` and `imageviewer.js` into this folder.

Description: 

The webpage has buttons to select the image sets to view.

Alt-click an imageset button to delete it.

Ctrl-click an imageset button to download it (be patient).

If you start a timelapse where the folder already exists, it will continue (e.g. on reboot)

## Motion detection




