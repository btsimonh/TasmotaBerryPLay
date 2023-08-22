# The Tasmota webcam build enables a lot of camera features.

The default driver is included in `tasmota32-webcam`

The enhanced V2 driver is enabled by an ADDITIONAL `#define USE_WEBCAM_V2` in user_config_override.h - this will give a perfomance boost, and adds the Berry features.

Motion detection uses a lot more flash, so is disabled by default.  Add both `#define USE_WEBCAM_V2` and `#define USE_WEBCAM_MOTION` to enable motion and image manipulation features.

If modifying user_config_override.h, build tasmota32-webcam, else you may not get PSRAM.

For ESP32-S3, build tasmota32s3-qio_opi-all to get PSRAM.

Note that inclusion of RTSP is controlled by `#define ENABLE_RTSPSERVER`, normally set in the webcam build.

Features only available in V2 are marked (2).  Features only available in V2 + Motion are marked(2+)



## The Camera
Camera use cases and features:

- View from the web GUI (mpjeg)
- Control parameters via commands
- stream via RTSP (e.g. to VLC or FFMPEG)
- (2) Timelapse implemented in Berry script
- (2+) Motion detection - Berry may be used to manage this.
- write photos to flash/SD Card is SCRIPTS are enabled
- (2) write photos to flash/SD Card using TAS commands
- (2) read photos direct from Berry (e.g. to send them somewhere else)
- (2+) read/write motion images (mask, diff, background) from Berry

## Basic usage

load the webcam firmware, and go.  Preferably set a valid [template](https://templates.blakadder.com/ai-thinker_ESP32-CAM.html)

The webui will then show you the picture feed.

(if you don't get one, then double check your boards actual connections, and set the pins appropriately)

## Basic commands

`WcSetResolution` 0-10 - set and store the resolution.  The resolution will have a big effect on the achievable framrerate for mjpeg or rtsp - as the frames get bigger, we simply don't have the bandwidth.

(2) Turn the cam display off and on from the Webgui.

`WcRtsp` - turn on and off rtsp serving.

## URLs

_(2) MJPEG and RTSP streams support multiple clients, but expect performance degradation with each additonal client_

_note OTHER things on your wifi network can have a big impact on streaming. 

Still pictures are available at:
- `http://<ip>/wc.jpg`
- `http://<ip>/wc.mjpeg`
- `http://<ip>/snapshot.jpg`
These all trigger a picture to be captured, and serve the resulting JPEG at the current resolution

(2) Still pictures available for motion detect: (404 if motion not enabled)
- `http://<ip>/motionbuff.jpg` - the last (decoder scaled) monochrome frame used for motion detection.
- `http://<ip>/motionlbuff.jpg` - the last (decoder and sw scaled) monochrome frame.
- `http://<ip>/motiondiff.jpg` - the last difference, if differences enabled, else 404
- `http://<ip>/motionmask.jpg` - the motion mask if enabled, else 404
- `http://<ip>/motionbackgroundbuff.jpg` - the motion background if enabled, else 404

MJPEG streams are available at:
- `http://<ip>:81/` - redirects to `/cam.mjpeg`.
- `http://<ip>:81/cam.mjpeg` - mjpeg stream.
- `http://<ip>:81/cam.jpg` - mjpeg stream.
- `http://<ip>:81/stream` - mjpeg stream.
- `http://<ip>:81/diff.mjpeg` - (2) mjpeg stream of motion images, else 404.

RTSP streams (if enabled):
- `rtsp://<ip>:8554/mjpeg/1` - multiple client support, but expect performance degradation with each additonal client

## Medium usage

### power off/on the hardware

`WcPowerOff` - (2) turn off the camera power

`WcInit` - turn on/reinit the camera.

### (2) Get a photo in Berry

`Wcgetpicstore0` - returns `{"addr":123456,"len":12345,"w":160,"h":120, "format":5}`

This can then be used to convert the addr/len to a Bytes object, and do what you like with it. (free with `WcGetFrame-1`, else it will be freed on the next request for a picture.).  E.g. save to google drive...

### (2) Save a picture locally

`WcSavePic0 filename` - take and save a jpeg image.  Use filename `/sd/filename` or `/sd/folder/filename` (folder must exit) to save to SD.

`WcAppendpic0 filename` - take a pic and append it to a file.


### (2+)Motion detection

`WcSetMotionDetect <timeinms>` - enable basic motion detection, operated at the period specified.

Expect debug logs when the motion detection total difference per 10000 pixels exceeds 1000....

`WcSetMotionDetect 0` - turn off computational motion detect.

Motion detection has 3 forms, and many options.

#### 1/ Motion by frame difference

Here, the difference between the last motion frame and the current motion frame is normalised to 10000 pixels (?), and compared with a limit.

`wcsetmotiondetect7 <limit>` - set the detection threshold - try 1000.

#### 2/ Motion by pixel different by > threshold

`wcsetmotiondetect3 <diff>` - set the pixel difference threshold (0-255).  pixels which differ more than this from the previous image are counted.

`wcsetmotiondetect4 <countthresh>` - set the count of pixels which must be different in 10000 pixels to trigger a motion event.

#### 3/ Motion by jpeg framesize

`wcsetmotiondetect2 <percent change>` - trigger a motion event if the jpeg size changes by more than the percent set.

(this is unproven in the wild as yet - but it can be enabled without other computaitonal motion detection, and is exffectively free in terms of CPU)

#### (2) Advanced motion features

`WCsetMotiondetect6 1|0` - turn on/off difference buffer 

The difference buffer is useful to see what is being detected.  If pixel difference is enabled, then difference buffer pixels are set to 255 for pixels over the configured threshold.

`WCsetMotiondetect5 0-7` - set the scale of motion detect images (default 3) 0-7 = 1, 1/2, 1/4, 1/8, 1/16, 1/32, 1/64, 1/128

values 0-3 use scaling on jpeg decode (fast).
values 4-7 add software scaling (not much performance gain, but some) 

`WCsetMotiondetect8 <frames> <threshold> <expansion>` - enable maskoing, and auto-create mask from the differences in the next `<frames>` motion detect runs - if a pixel is over `<threshold>` different to the last image, draw a square on the mask (the pixel expanded by `<expansion>`

Using ths feature, you can exclude areas which are affected by wind, etc.  The mask is then available in the above URL to check.

`WcGetmotionpixelsN` (N=1..4) read addr, len, w, h as JSON {"addr":123456,"len":12345,"w":160,"h":120, "format":4} 
 
motion(1), difference(2) buffer - e.g for berry, mask(3), background(4) e.g. could be used to read pixels, or change pixels from berry.

## (2) Advanced usage

`WcSetoptions24 <frames to skip at input>` - e.g. WcSetoptions24 2 will give you only every 3rd frame

`WcSetoptions25 <camPixelFormat>` - (did not get this to work on my cam) espcam format + 1.  0->default->JPEG.   1:2BPP/RGB565, 2:2BPP/YUV422, 3:1.5BPP/YUV420, 4:1BPP/GRAYSCALE 5:JPEG/COMPRESSED 6:3BPP/RGB888 7:RAW 8:3BP2P/RGB444 9:3BP2P/RGB555
 
`WcConvertFrameN <format> <scale>` - (2+) convert a wcgetframe in picstore from jpeg to `<format>` (0=2BPP/RGB565, 3=1BPP/GRAYSCALE, 5=3BPP/RGB888), `<scale>` (0-3)
 
converts in place, replacing the stored frame with the new format.  Data can be retrieved using wcgetpicstoreN (e.g. for use in berry). will fail if it can't convert or allocate.

`WcSetPicture` - (2+) SetPictureN (N=1-MAX_PICTORE) expects `addr len format [width height]`
 
use to populate a frame in Wc.picstore from Berry.  e.g. to put a JPEG mask there so you can then decode it, get it's address, get the address of the current mask, and copy data across.
 
if sending JPEG (format=0|5), width and height are calculated on decode. if sending pixels (format=4(GRAY)|6(RGB)|1(RGB565)), width and height are required, and used to allocate. binary data is copied from addr.  i.e. you can send the addr/len from Berry introspect bytes.
 
ideas: could be used to set background image based on time of day.

### Go faster?

`wcclock <mhz>` - set the cam clock.  Input Framerate directly correlates to this.  Going to high will result in failure!!! (default 20)

_NOTE: the clock rate can have an impact on wifi in poorly designed boards.  e.g. on the Freenove esp32-S3 board, the default of 20mhz kills the wifi, but using 13 or 23 improves it.  So if you are getting poor performance, check the wifi performance, and if bad, change the wcclock value_

## (2) Berry Calls

The driver calls a method 'webcam' on any driver which has it.

(2+) Cmd `motion` - indicates a motion event.  payload `{"val":%d,"bri":%d,"pix":%d}`

(2+) Cmd `framesizechange` - indicates a framesize change motion event.  payload `{"diff":%d}` (percent)

Cmd `frame` - called each received frame, only is `wcBerryFrames 1` is set.  payload `{"len":%d}`

e.g.
```
# this is to be loaded as a driver
class motiondriver
    def webcam(cmd, idx, payload, x)
        if cmd == 'motion'
            print(payload)
        end
    end
end
```

See https://github.com/btsimonh/TasmotaBerryPLay/tree/master/timelpase for some WIP example code implementing timelapse and motion capture, optionally saving to SD or posting to http.

