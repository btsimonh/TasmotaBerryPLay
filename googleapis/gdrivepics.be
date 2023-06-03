import string
import introspect

#load('/googleoath.be')
#load('/googledrive.be')

var auth = google_oauth("/google.json", "https://www.googleapis.com/auth/drive");
var gdrive = google_drive(auth)

var piccount = 0
var folder_id = "1evt2oAqN0xQ8mQOj8KYDUR4Om7QTrvna"

def uploadPicNow()
  var cmd = "wcgetpicstore 0"; # force a read into the first buffer, and return the buffer addr/len
  var resobj = tasmota.cmd(cmd);
  # res like {"WCGetpicstore":{"addr":123456,"len":20000,"buf":1}
  var addr = resobj['WCGetpicstore']['addr']
  var len = resobj['WCGetpicstore']['len']
  if len
    print('got picture')
    var p = introspect.toptr(addr) # p is now of type ptr:
    var b = bytes(p, len) # b is now an unmanaged bytes object:  b.ismapped() should return true
    print(b)
    gdrive.write(folder_id, 'frame' .. piccount .. '.jpeg', b)
    piccount = piccount + 1
  else 
    print('no picture')
  end
end

uploadPicNow()
uploadPicNow()
uploadPicNow()
