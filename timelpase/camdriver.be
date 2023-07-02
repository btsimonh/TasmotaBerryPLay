import json
import path
import string
import webserver

def zap(folder, diag)
  if !folder || folder == '/'
    print('refusing to zap root')
    return false
  end  
  if folder == '/sd' || folder == '/sd/'
    print('refusing to zap sd root')
    return false
  end  
  if diag print('zap '+folder) end
  if folder[-1] == '/'
    if diag print('remove trailing slash '+folder) end
    folder = folder[0..-2]
  end
  if path.exists(folder)
    var files = ['blaa']
    while size(files)
      # may only give the first 25...
      files = path.listdir(folder)
      if !size(files)
        if diag print(folder..' is empty') end
      end
      
      for f:files
        if !path.remove(folder .. '/' .. f)
          zap(folder .. '/' .. f)
        else
          if diag print('deleted file '..folder .. '/' .. f) end
        end
      end
      if !path.rmdir(folder)
        if diag print('failed to remove '..folder) end
      else
        if diag print('removed '..folder) end
        return true
      end
    end
  else
    if diag print('folder '..folder ..' does not exist') end
  end
  return false
end

def cmdZapFolder(cmd, idx, payload, payload_json)
    if payload && size(payload)
        var imgfolder = payload
        if zap(imgfolder, 1)
            print('zapped '..imgfolder)
            tasmota.resp_cmnd_done()
            return
        end
        print('zap '..imgfolder.. ' failed')
    end
    tasmota.resp_cmnd_error()
end
tasmota.add_cmd('zapfolder', cmdZapFolder)


# this is to be loaded as a driver
class camdriver
    var defaultmotionoptions
    var defaulttimelapseoptions
    var motionoptionslist
    var timelapseoptionslist

    var motion
    var timelapse

    var currday

    def init()
        print('webcam init')
        self.motion = {
            'state':0
        }
        self.timelapse = {
            'state':0
        }

        self.defaultmotionoptions = {
            'enable':0,
            'interval':3000,
            'holdoff_s':30,
            'basefolder':"/sd/timelapse",
            'folder':"motion",
            'hourlimitlow':0,
            'hourlimithi':0,
            'changethresh':1000,
            'savediff':0,
            'pixthresh':0,
            'pixcountthresh':0,
            'folderperday':true,
            'multipic':1
        }

        self.motionoptionslist = [
            "enable",
            "interval",
            "basefolder",
            "folder",
            "hourlimitlow",
            "hourlimithi",
            "changethresh",
            "savediff",
            "pixthresh",
            "pixcountthresh",
            "folderperday",
            "multipic",
            "holdoff_s"
        ]

        self.defaulttimelapseoptions = {
            'enable':0,
            'basefolder':"/sd/timelapse",
            'folder':"tl",
            'cronstring':'*/1 * * * *', # e.g. '*/1 * * * *'
            'hourlimitlow':0,
            'hourlimithi':0,
            'interval':0, # if set, use a timer, not cron
            'multipic':1,
            'holdoff_s':0
        }

        self.timelapseoptionslist = [
            "enable",
            "basefolder",
            "folder",
            "cronstring",
            "hourlimitlow",
            "hourlimithi",
            "interval",
            "multipic",
            "holdoff_s"
        ]
        print('webcam initialised defaults')

        self.start()
    end

    def copyoptions(optlist, dest, opts, defaults)
        #print('copyoptions')
        #print(optlist)
        #print(dest)
        #print(opts)
        #print(defaults)

        for opt:optlist
            #print(opt)
            if defaults.contains(opt)
                dest[opt] = defaults[opt]
            end
            if opts.contains(opt)
                dest[opt] = opts[opt]
            end
        end
    end

    def stop()
        self.stopmotion()
        self.stoptimelapse()
    end

    def start()
        self.stop()
        var f
        try
            f = open('/motion.json', 'r')
        except ..
            print('did not open /motion.json')
        end

        if f
            var options = f.read();
            f.close()
            options = json.load(options)
            print('read /motion.json')
            self.copyoptions(self.motionoptionslist, self.motion, options, self.defaultmotionoptions)
            print('motion options:'..self.motion)
            self.startmotion()
        else
            print('write default motion.json')
            f = open('/motion.json', 'w')
            var options = {}
            self.copyoptions(self.motionoptionslist, self.motion, options, self.defaultmotionoptions)
            f.write(json.dump(self.defaultmotionoptions, 'format'))
            f.close();
        end

        f = nil
        try
            f = open('/timelapse.json', 'r')
        except ..
            print('did not open /timelapse.json')
        end
        if f
            var options = f.read();
            f.close()
            options = json.load(options)
            print('read /timelapse.json')
            self.copyoptions(self.timelapseoptionslist, self.timelapse, options, self.defaulttimelapseoptions)
            print('timelapse options:'..self.timelapse)
            self.starttimelapse()
        else
            print('write default timelapse.json')
            f = open('/timelapse.json', 'w')
            var options = {}
            self.copyoptions(self.timelapseoptionslist, self.timelapse, options, self.defaulttimelapseoptions)
            f.write(json.dump(self.defaulttimelapseoptions, 'format'))
            f.close();
        end
    end

    # turn off any features we may have turned on
    # and stop the motion detection
    def stopmotion()
        if self.motion['state']
            var cmd = "wcsetmotiondetect6 0"
            var resobj = tasmota.cmd(cmd);
            cmd = "wcsetmotiondetect3 0"
            resobj = tasmota.cmd(cmd);
            cmd = "wcsetmotiondetect4 0"
            resobj = tasmota.cmd(cmd);
            cmd = "wcsetmotiondetect 0"
            resobj = tasmota.cmd(cmd);
            print('stopped motion '..self.motion['folder'])
            self.motion['state'] = 0
        end
    end

    def startmotion()
        var options = self.motion;
        if options['state']
            self.stopmotion()
        end

        if !options['enable']
            return
        end
        if options['state'] == 0
            options['state'] = 1
            # we may read this from the folder json later
            options['frame'] = 0
            options['ignorebeforetime'] = 0
            self.newfolder(options)

            var cmd
            var resobj

            # overall normalised picture difference to cause detection
            if options['changethresh']
                cmd = "WCsetMotiondetect7 "..options['changethresh']
                resobj = tasmota.cmd(cmd);
            end

            cmd = "wcsetmotiondetect "..options['interval']
            resobj = tasmota.cmd(cmd);

            # we want diff images as well
            if options['savediff']
                # turn on diff
                cmd = "wcsetmotiondetect6 1"
                resobj = tasmota.cmd(cmd);
            end

            # set the pixel difference threshold
            if options['pixthresh']
                cmd = "wcsetmotiondetect3 "..options['pixthresh']
                resobj = tasmota.cmd(cmd);
            end

            # set count of pixels different - different/additional motion detection method
            if options['pixcountthresh']
                cmd = "wcsetmotiondetect4 "..options['pixcountthresh']
                resobj = tasmota.cmd(cmd);
            end

            print('started motion '..options['folder'])
        end
    end

    def stoptimelapse()
        if self.timelapse['state']
            self.timelapse['state'] = 0
            tasmota.remove_timer("timelapsetakepic"..self.timelapse['folder'])
            tasmota.remove_cron("timelapse"..self.timelapse['folder'])  
            print('stopped timelapse '..self.timelapse['folder'])
        end
    end

    def starttimelapse()
        var options = self.timelapse;
        if options['state']
            self.stoptimelapse()
        end
        if !options['enable']
            return
        end
        if options['state'] == 0
            options['state'] = 1
            options['frame'] = 0
            options['ignorebeforetime'] = 0
            options['savediff'] = 0
            self.newfolder(options)

            # save pic at start
            self.savepic(options, {})

            if options['interval'] # don't use cron
                self.starttimelapsetimer()
                print('started timelapse '..options['folder']..' at interval '..options['interval']..'ms')
            else 
                self.starttimelapsecron()
                print('started timelapse '..options['folder']..' at times ['..options['cronstring']..']')
            end
        end
    end

    def starttimelapsetimer()
        def reached()
            print('timer '..self.timelapse['interval']..'ms')
            self.savepic(self.timelapse, {})
            tasmota.set_timer(self.timelapse['interval'], reached, self.timelapse['folder'].."takepic")
        end
        tasmota.set_timer(self.timelapse['interval'], reached, self.timelapse['folder'].."takepic")
    end
    def starttimelapsecron()
        def reached()
            if self.timelapse['state']
                print('cron ['..self.timelapse['cronstring']..']')
                self.savepic(self.timelapse, {})
            end
        end
        #try
            tasmota.add_cron(self.timelapse['cronstring'], reached, "timelapse"..self.timelapse['folder'])
        #except ..
        #    print('invalid cron?:'..self.timelapse['cronstring'])
        #end
    end

    # create or read json from a folder with today's date.
    def newfolder(options)
        print('new folder')
        var time = tasmota.rtc()
        var local = time['local']
        var t = tasmota.time_dump(local)
        print(t)
        self.currday = t['day']
        print(self.currday)
        if path.mkdir(options['basefolder'])
            print('created folder '..options['basefolder'])
        end
        options['currfolder'] = options['basefolder']..'/'..options['folder'] .. t['year'] .. '-' .. t['month'] ..'-' .. t['day']
        print('try create folder '..options['currfolder'])
        if path.mkdir(options['currfolder'])
            print('created folder '..options['currfolder'])
        end
        options['currfolder'] = options['currfolder'] .. '/'

        # read firstframe and frame from config.json if it exists.
        var configread = 0;
        # set defaults
        options['frame'] = 0
        options['firstframe'] = 0

        var f
        try
            f = open(options['currfolder'] .. 'config.json', 'r')
        except ..
            print('did not open '..options['currfolder'] .. 'config.json')
        end
        if f
            var config = f.read();
            f.close()
            var configmap = json.load(config);
            if configmap
                print(configmap)
                options['frame'] = configmap['frame']
                options['firstframe'] = configmap['firstframe']
                configread = 1
            end
        end

        # if no config file in the folder,
        # then firrtframe will be current frame
        if !configread
            options['foldersChanged'] = 1
            options['firstframe'] = options['frame']
            self.updateconfig(options)
        end

        #refresh the list of folders
        self.updatelist(options)
    end

    # write config.json in the current folder
    # this is the complete options used to write
    # the last image, but including 'firstframe' and 'frame'
    def updateconfig(options)
        var config = json.dump(options, 'format');
        var f
        try
            f = open(options['currfolder'] .. 'config.json', 'w')
        except ..
            print('could not write '..options['currfolder'] .. 'config.json')
        end
        if f
            f.write(config)
            f.close()
            # print('wrote config' .. config)
        end
    end

    # writes a list of folders to folders.json in 
    # the base folder for this options struct.
    def updatelist(options)
        var folders = path.listdir(options['basefolder'])
        options['foldersChanged'] = 0

        var config = '{"folders":['
        var addcomma
        for f:folders
            print(f)
            print(string.find(f, '.'))
            if string.find(f, '.') < 0
                if addcomma
                    config = config .. ','
                end
                config = config .. '"'..f..'"'
                addcomma = 1
            end
        end
        config = config .. ']}';

        var f
        try
            f = open(options['basefolder'] .. '/folders.json', 'w')
        except ..
            print('could not write '..options['basefolder'] .. '/folders.json')
        end
        if f        
            f.write(config)
            f.close()
        end
    end


    def savepic(options, details)
        # if set for only cetain times of day, just check
        print(options)
        print(details)
        var time = tasmota.rtc()
        var local = time['local']
        var t = tasmota.time_dump(local)
        if (options['hourlimitlow'] != options['hourlimithi'])
            if t['hour'] < options['hourlimitlow']
                return
            end
            if t['hour'] > options['hourlimithi']
                return
            end
        end

        if options['ignorebeforetime'] > local
            print('motion: holding off for '..(options['ignorebeforetime']-local)..' more seconds')
            return
        end
        options['ignorebeforetime'] = local + options['holdoff_s']

        var pic = 0
        while pic < options['multipic']
            pic = pic + 1
            var picname = "frame" .. options['frame'] .. '.jpg'
            var diffname = "diff" .. options['frame'] .. '.jpg'
            var picjson = "frame" .. options['frame'] .. '.json'
            details['frame'] = picname

            # save a fullres
            # wcsavepic0 waits for the next frame to complete, then saves it.
            var cmd = "wcsavepic0 ".. options['currfolder'] .. picname
            var resobj = tasmota.cmd(cmd);
            print('saved pic '..cmd..resobj)


            # only get diff for first pic of multipic
            if options['savediff'] && pic == 0
                # copy the diff image into slot 2
                print('save diff')
                cmd = "wcGetmotionpixels2 2"
                resobj = tasmota.cmd(cmd);
                print(resobj)
                # jpeg encode it in slot 2
                cmd = "wcConvertPicture2 0"
                resobj = tasmota.cmd(cmd);
                # save the encoded jpeg.
                cmd = "wcsavepic2 ".. options['currfolder'] .. diffname
                resobj = tasmota.cmd(cmd);
                details['diff'] = diffname
            end

            time = tasmota.rtc()
            print(time)
            local = time['local']
            print(local)

            t = tasmota.time_str(local)
            details['time'] = t

            # write the json file to hold metadata about the image(s)
            var f
            try
                f = open(options['currfolder'] .. picjson, 'w')
            except ..
                print('could not write '..options['currfolder'] .. picjson)
            end
            if f
                var d = json.dump(details, 'format');
                f.write(d)
                f.close()
            end
            options['frame'] = options['frame'] + 1
        end
        self.updateconfig(options)
    end


    # callback from webcam driver in tas on motion or other event 
    def webcam(cmd, idx, payload, x)
        # called when motion is detected
        if cmd == 'motion'
            var payloadmap = json.load(payload)
            self.savepic(self.motion, payloadmap)
        end

        # called when framesize changed by more than the configured amount.
        if cmd == 'framesizechange'
            print(cmd..payload)
        end

        # called every frame if enabled
        if cmd == "frame"
            print('frame'..payload)
        end
    end

    def testmotion()
        self.webcam('motion', 0, '{"val":1000,"bri":15000,"pix":20}', {"val":1000,"bri":15000,"pix":20})
    end

    def getlink(url, newpage, text)
        var js = "window.open('" .. url .."'"
        if newpage
            js  = js .. ",'_blank'" 
        else
            js  = js .. ",'_self'" 
        end
        js = js .. ")"

        return '<p></p><button onclick="' .. js .. '">' .. text .. '</button>'
    end

    def web_add_main_button()
        var url = '/fs'..self.timelapse['basefolder']..'/index.html'
        var newpage = 1
        var text = 'Timelapse Viewer'

        webserver.content_send(self.getlink(url, newpage, text))
        if self.timelapse['basefolder'] != self.motion['basefolder']
            url = '/fs'..self.motion['basefolder']..'/index.html'
            newpage = 1
            text = 'Motion Viewer'
            webserver.content_send(self.getlink(url, newpage, text))
        end
        webserver.content_send("<p></p><button onclick='la(\"&m_bewebcam=1\");'>Start/Restart Berry Webcam</button>")
        webserver.content_send("<p></p><button onclick='la(\"&m_bewebcam=2\");'>Stop Berry Webcam</button>")
    end

    def web_sensor()
        print('web_sensor')
        if webserver.has_arg("m_bewebcam")
            var val = webserver.arg("m_bewebcam");
            print('m_bewebcam'..val)
            if val == '1'
                self.start()
            else
                self.stop()
            end
        end
    end

end


# if this is second run, remove the existing driver.
if global.webcam
  print("removing existing driver")
  tasmota.remove_driver(global.webcam)
  global.webcam = nil
else
  # do nothing - normal first run
  print("first run, no driver to remove")
end

global.webcam = camdriver() 
tasmota.add_driver(global.webcam)
print("driver added")


