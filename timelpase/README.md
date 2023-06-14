# Timelpase using Berry in Tasmota

load zap.be
load timelapse.be

First run will create /sd/timelapse/
Put index.html into this folder.

create a timelapse with

tl = timelpase(folder, intervalms)

See the timelpase via http://<ip>/fs/sd/timelapse/index.html

multiple timelpases can be running at the same time.

The webpage has buttons to select the image sets to view.

Alt-click an imageste button to delete it.

Stop a timelapse with
tl.stop()

If you start a timelapse where the folder already exists, it will continue (e.g. on reboot)


## timelapse viewer



