import json
import string

#load('/googleoath.be')

class google_drive
  var auth
  def init(auth)
    self.auth = auth
  end
  def write(folderid, name, bytesdata)
    # first, create the file, and read it's id
    var cl = webclient()
    cl.begin('https://www.googleapis.com/drive/v3/files?uploadType=media')
    #print('begin file create')
    var body = '{"name":"' .. name .. '","parents":["' .. folderid .. '"]}'
    self.auth.add_access_key(cl)
    var r = cl.POST(body)
    if r == 200
      var s = cl.get_string();
      #print('file created ' .. s)

      var id = json.load(s)['id']
      #print('file id ' .. id)
      var clfile = webclient()
      var url = 'https://www.googleapis.com/upload/drive/v3/files/' ..id .. '?uploadType=media'
      #print(url)
      clfile.begin(url)
      #print('begin file upload')
      body = bytesdata
      self.auth.add_access_key(clfile)
      #print('posting')
      r = clfile.PATCH(body)
      #print('posted' .. r)
      var resp = clfile.get_string();
      if r == 200
        print('uploaded ' .. name)
      else
        print('upload of ' .. name .. ' failed ' .. r)
        print(resp)
      end
      return resp
    else
      print('file create failed' .. r .. resp)
      return resp
    end
  end
end

# example
# var auth = google_oauth("/google.json", "https://www.googleapis.com/auth/drive");
# var gdrive = google_drive(auth)
# var folder_id = "1evt2oAqN0xQ8mQOj8KYDUR4Om7QTrvna"
# var resp = gdrive.write(folder_id, 'mytestfile.txt', "text text or bytes")

