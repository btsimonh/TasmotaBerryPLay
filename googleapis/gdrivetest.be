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
#resp = gdrive.readdir('root')
#print('all files ')
#print(resp)

#var newfolderid = gdrive.mkdir(folder_id, 'tl2')

#resp = gdrive.write(newfolderid, 'mytestfile.txt', "text text or bytes")


# list only files which are 'in' the folder
#resp = gdrive.readdir(folder_id)

#works
#resp = gdrive.readdir(nil, "sharedWithMe", "files(id,shared,name,kind,mimeType,parents,ownedByMe)")

# works....
#resp = gdrive.readdir(nil, "mimeType%20=%20'application/vnd.google-apps.folder'", "files(id,shared,name,kind,mimeType,parents,ownedByMe,owners)")

#works
#resp = gdrive.readdir(nil, "visibility='limited'", "files(id,shared,name,kind,mimeType,parents,ownedByMe)")

#name = 'hello' is encoded as name+%3d+%27hello%27

#works, but all except one file are mine anyway.
resp = gdrive.readdir(nil, "%27me%27%20in%20owners%20and%20%27root%27%20in%20parents", "files(id,shared,name,kind,mimeType,parents,ownedByMe,trashed)")


#%20and%20shared%20=%20'false'

print('folder files')
print(resp)
var files = resp['files']

print(size(files))

var deleted = 0
var total = 0
for file:files
  print(file)
  if file['kind'] == 'drive#file'
    total = total + 1
    #print('would delete ' .. file['name'])
    #resp = gdrive.delete(file['id'])
    var parentcount = 0
    if file.contains('parents')
      parentcount = size(file['parents']);
    end
    if file.contains('ownedByMe') && file.contains('shared')
      if file['ownedByMe'] && !file['shared']
        print('would delete ' .. file['name'])
        deleted = deleted + 1
      end
    end
  else
    print(file['name'] .. ' not a file')
  end
end
print('' .. deleted .. '/' .. total)
