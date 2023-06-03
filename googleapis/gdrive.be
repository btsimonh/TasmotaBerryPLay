import json
import string

#load('/googleoath.be')

class google_drive
  var auth
  def init(auth)
    self.auth = auth
  end
  
  def readdir(folderid, query)
    var cl = webclient()
    
    var url = 'https://www.googleapis.com/drive/v3/files?trashed=false'
    if folderid
      url = url .. "&q=%22" .. folderid .. "%22%20in%20parents"
    end
    if query
      url = url .. "&q=" .. query
    end
    print(url)
    cl.begin(url)
    
    self.auth.add_access_key(cl)
    #print('begin readdir')
    var r = cl.GET()
    var s = cl.get_string()
    var m = json.load(s)
    if r != 200
      print('readdir failed ' .. r)
    end
    return m
  end
  
  def delete(fileid)
    var cl = webclient()
    var url = 'https://www.googleapis.com/drive/v3/files/' .. fileid 
    print(url)
    cl.begin(url)
    self.auth.add_access_key(cl)
    print('begin delete')
    var r = cl.DELETE("")
    print('called delete')
    var s = cl.get_string()
    print('resp str ' .. s)
    var m = json.load(s)
    print('resp map ' .. m)
    if r != 204 # note google returns 'No Content' if delete success, and body of resp is empty.
      print('delete failed ' .. r)
    end
    return m
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
  
  def getparents(fileid)
    var cl = webclient()
    var url = 'https://www.googleapis.com/drive/v2/files/' .. fileid .. '/parents'
    print(url)
    cl.begin(url)
    self.auth.add_access_key(cl)
    #print('begin getparents')
    var r = cl.GET()
    #print('called get')
    var s = cl.get_string()
    #print('resp str ' .. s)
    var m = json.load(s)
    #print('resp map ' .. m)
    if r != 200
      print('get parents failed ' .. r)
      print('resp map ' .. m)
    end
    return m
  end

  # delete all files in the sevice root which are not in a user folder
  def cleanservicefiles()
    # list everything the service account can see.
    # this will include ALL files and folders
    #var q = "sharedWithMe%20=%20false"
    var resp = self.readdir(nil)
    var files = resp['files']
    print('listed '.. size(files) ..' files')
    var deleted = 0
    var total = size(files)
    for file:files
      if file['kind'] == 'drive#file' && file['mimeType'] != 'application/vnd.google-apps.folder'
        resp = self.getparents(file['id'])
        if (resp)
          var parentcount = size(resp['items']);
          if 1 == size(resp['items']) && resp['items'][0]['isRoot']
            parentcount = 0
          end
          if !parentcount
            print(file['name'] .. ' only in root of service account - deleting')
            resp = gdrive.delete(file['id'])
            deleted = deleted + 1
          else
            print(file['name'] .. ' still reffed by others')
          end
        else
          print(file['name'] .. ' getparents failed')
        end
      else
        print(file['name'] .. ' not a file')
      end
    end
    print('Deleted '..deleted..'/'..total)
  end

end

# example
# var auth = google_oauth("/google.json", "https://www.googleapis.com/auth/drive");
# var gdrive = google_drive(auth)
# var folder_id = "1evt2oAqN0xQ8mQOj8KYDUR4Om7QTrvna"
# var resp = gdrive.write(folder_id, 'mytestfile.txt', "text text or bytes")

