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

class timelapse
    var interval
    var folder
    var frame
    var base
    var state
    var hourlimitlow
    var hourlimithi


    def init(folder, interval, low, hi)
        self.state = 0
        self.hourlimitlow = 0
        self.hourlimithi = 0
        if low self.hourlimitlow = low end
        if hi self.hourlimithi= hi end

        self.base = imagebase
        self.interval = interval
        self.frame = 0
        path.mkdir(self.base)
        self.folder = self.base .. '/' ..folder
        path.mkdir(self.folder)
        self.folder = self.folder .. '/'

        print('tlapse interval '..self.interval..'ms')

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
            self.interval = configmap['interval']
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

    def savepic()

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
            print('{"time":"'..t..'"}')
            f.write('{"time":"'..t..'"}')
            f.close()
        end

        self.frame = self.frame + 1
        self.updateconfig()
        # restart timer
        self.start()
    end

    def stop()
        self.state = 0
        tasmota.remove_timer(self.folder.."update")
        tasmota.remove_timer(self.folder.."takepic")
        print('stopped timelapse '..self.folder)
    end

    def start()
        if self.state == 0
            self.state = 1
            print('started timelapse '..self.folder)
            self.savepic()
        end
        if self.state == 1
            def reached()
                if self.state
                    print('timer')
                    #ignore if outside of hour limits
                    if (self.hourlimitlow != self.hourlimithi)
                        var t = tasmota.time_dump()
                        if t['hour'] <= self.hourlimitlow
                            tasmota.set_timer(self.interval, reached, self.folder.."takepic")
                            return
                        end
                        if t['hour'] > self.hourlimithi
                            tasmota.set_timer(self.interval, reached, self.folder.."takepic")
                            return
                        end
                    end

                    self.state = 1

                    self.savepic()
                end
            end
            print('set timer now + '..self.interval..'ms')
            tasmota.set_timer(self.interval, reached, self.folder.."takepic")
            self.state = 2 # waiting on timer
        end
    end
end


