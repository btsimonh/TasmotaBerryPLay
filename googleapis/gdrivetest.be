#load('/googleoath.be')
#load('/googledrive.be')

var auth = google_oauth("/google.json", "https://www.googleapis.com/auth/drive");

auth.get_oath_token(3600)
print(auth.access_token)

var gdrive = google_drive(auth)

# !!!!change to the folder id of a folder you shared with your service account...!!!!
# (or try one which has public write access??? maybe)
var folder_id = "1evt2oAqN0xQ8mQOj8KYDUR4Om7QTrvna"

# example
var resp = gdrive.write(folder_id, 'mytestfile.txt', "text text or bytes")
print(resp)
