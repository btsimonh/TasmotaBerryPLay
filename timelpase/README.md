# Timelapse/Motion using Berry in Tasmota

merge this [PR](https://github.com/arendst/Tasmota/pull/18859) into your branch, and `#define UFILESYS_STATIC_SERVING`

load zap.be (https://github.com/tasmota/Berry_playground/pull/21)
load timelapse.be

First run will create /sd/timelapse/
Put `index.html` and `imageviewer.js` into this folder.

Description: 

create a timelapse with

`tl = timelpase(folder, intervalms)`

e.g. `tl = timelpase('test1', 30000)`

See the timelpase via http://<ip>/fs/sd/timelapse/index.html

multiple timelpases can be running at the same time.

The webpage has buttons to select the image sets to view.

Alt-click an imageset button to delete it.

Ctrl-click an imageset button to download it (be patient).

Stop a timelapse with
tl.stop()

If you start a timelapse where the folder already exists, it will continue (e.g. on reboot)


## Motion detection

modify motion.be for your folder and parameters, then load it.

it ends with:
```
webcam = motiondriver('motion', 3000, 4, 20)
tasmota.add_driver(webcam)
print("driver added")
```

motiondriver params are (subfolder, intervalms, hour to start, hour to stop)

omage save is suppressed outside of active hours.

The viewer will show you the motion folder.


