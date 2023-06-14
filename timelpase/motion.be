import json
import path
import string

var zap

var loadres = load('/zap.be')
print(loadres)

var imagebase = '/sd/timelapse'
var foldersChanged = 1;

def cmdZapImgFolder(cmd, idx, payload, payload_json)
    if payload && size(payload)
        var imgfolder = imagebase..'/'..payload
        if zap(imgfolder, 1)
            print('zapped '..imgfolder)
            tasmota.resp_cmnd_done()
            foldersChanged = 1
            return
        end
        print('zap '..imgfolder.. ' failed')
    end
    tasmota.resp_cmnd_error()
end
tasmota.add_cmd('zapimagefolder', cmdZapImgFolder)

# this is to be loaded as a driver
class motiondriver
    var interval
    var folder
    var frame
    var base
    var state
    var hourlimitlow
    var hourlimithi

    def init(folder, interval, low, hi)
        self.state = 0
        self.interval = interval
        self.hourlimitlow = 0
        self.hourlimithi = 0
        if low self.hourlimitlow = low end
        if hi self.hourlimithi= hi end

        self.base = imagebase
        self.frame = 0
        path.mkdir(self.base)
        self.folder = self.base .. '/' ..folder
        path.mkdir(self.folder)
        self.folder = self.folder .. '/'

        if !path.exists(self.folder .. 'config.json', 'r')
            self.updateconfig()
        end

        #refresh the list of folders
        self.updatelist()

        var f = open(self.folder .. 'config.json', 'r')
        if f
            var config = f.read();
            f.close()
            var configmap = json.load(config);
            if !configmap 
                self.updateconfig()
                f = open(self.folder .. 'config.json', 'r')
                if f
                    config = f.read();
                    f.close()
                    configmap = json.load(config);
                end
            end
            print(configmap)
            self.frame = configmap['frame']
        end

        self.start()

        def update()
            # if we delete a folder, then remove from the list.
            if foldersChanged
                print('detect folders changed by delete')
                self.updatelist()
            end
            tasmota.set_timer(1000, update, self.folder.."update")
        end
        tasmota.set_timer(1000, update, self.folder.."update")

    end

    def updateconfig()
        var config = '{"frame":'..self.frame..', "interval":'..self.interval..'}';
        var f = open(self.folder .. 'config.json', 'w')
        f.write(config)
        f.close()
        print('write config' .. config)
    end

    def updatelist()
        var folders = path.listdir(self.base)
        foldersChanged = 0

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

        var f = open(self.base .. '/folders.json', 'w')
        f.write(config)
        f.close()
    end

    def savepic(details)

        var picname = "frame" .. self.frame .. '.jpg'
        var picjson = "frame" .. self.frame .. '.json'
        var cmd = "wcsavepic0 ".. self.folder .. picname
        var resobj = tasmota.cmd(cmd);
        var time = tasmota.rtc()
        print(time)
        var local = time['local']
        print(local)

        var t = tasmota.time_str(local)
        print(t)

        var f = open(self.folder .. picjson, 'w')
        if f
            details['time'] = t
            var d = json.dump(details, 'format');
            f.write(d)
            f.close()
        end

        self.frame = self.frame + 1
        self.updateconfig()
    end

    def stop()
        self.state = 0
        var cmd = "wcsetmotiondetect 0"
        var resobj = tasmota.cmd(cmd);
        tasmota.remove_timer(self.folder.."update")
        print('stopped motion '..self.folder)
    end

    def start()
        if self.state == 0
            self.state = 1
            var cmd = "wcsetmotiondetect "..self.interval
            var resobj = tasmota.cmd(cmd);
            print('started motion '..self.folder)
        end
    end

    def webcam(cmd, idx, payload, x)
        if cmd == 'motion'
            var payloadmap = json.load(payload)
            self.savepic(payloadmap)
        end
    end

    def framesizechange(cmd, idx, payload, x)
        print('framesizechange ')
        print(cmd)
        print(idx)
        print(payload)
        print(x)
    end
end


# if this is second run, remove the existing driver.
if global.webcam
  print("removing existing driver")
  tasmota.remove_driver(global.webcam)
else
  # do nothing - normal first run
  print("first run, no driver to remove")
end
  
webcam = motiondriver('motion', 3000, 4, 20)
tasmota.add_driver(webcam)
print("driver added")
