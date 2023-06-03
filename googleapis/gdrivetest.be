#load('/googleoath.be')
#load('/googledrive.be')

var auth = google_oauth("/google.json", "https://www.googleapis.com/auth/drive");

var gdrive = google_drive(auth)

# !!!!change to the folder id of a folder you shared with your service account...!!!!
# (or try one which has public write access??? maybe)
var folder_id = "1evt2oAqN0xQ8mQOj8KYDUR4Om7QTrvna"

# example
#var resp = gdrive.write(folder_id, 'mytestfile.txt', "text text or bytes")
#print(resp)


# list everything the service account can see.
# this will include ALL files and folders
resp = gdrive.readdir('root')
print('all files ')
print(resp)

# list only files which are 'in' the folder
#resp = gdrive.readdir(folder_id)
#print('folder files')
#print(resp)
#var files = resp['files']

print(size(files))

for file:files
  if file['kind'] == 'drive#file' && file['mimeType'] != 'application/vnd.google-apps.folder'
    #print('would delete ' .. file['name'])
    #resp = gdrive.delete(file['id'])
    
    #print('chown ' .. file['name'])
    #resp = gdrive.chown(file['id'], 'btsimonh@googlemail.com')
    
    resp = gdrive.getparents(file['id'])
    var parentcount = size(resp['items']);
    if 1 == size(resp['items']) && resp['items'][0]['isRoot']
      parentcount = 0
    end
    if !parentcount
      print(file['name'] .. ' only in root of service account')
    else
      print(file['name'] .. ' still reffed by ' .. parentcount .. 'others')
    end
  else
    print(file['name'] .. ' not a file')
  end
end

