## Files in this folder relate to the use of Google APIs from Tasmota.

From information gleaned from [here](https://medium.com/@nschairer/automating-google-drive-uploads-with-google-drive-api-curl-196989ffb6ce) we find that you can authorise access to google APIs using a service account.

With a focus on wanting to upload images to a folder in my personal Google Drive, I persued this.  Following the link above, first you create a Service account in the Google cloud console, then share a folder from your personal drive with the service account email.  Then from the service account, add an API key, and download the JSON file.

I stored this json file in the Tasmota filesystem.  From the content of the JSON, we create a JWT, and sign it with one of the keys in the JSON file (thankyou to @s-hadinger for adding the required signing features in latest dev branch).  This JWT is then used to request an access token from google, with which you can then access the APIs.

The google API documentation is not great - it's quite hard to find out how to use it without using a library.

**BEWARE - files written are OWNED b the service account. i.e. they are NOT 'in' your drive - they are in the service account's drive.  Hence if you remove them from your drive, they still exist...  and I don't know if as a user, you can delete them?**

**Edit: note new delete functions, and cleanservicefiles**


### Requirements

Ensure that yout TAS is latest dev branch, and has at least:
```
#define USE_BERRY_CRYPTO_RSA
#define USE_WEBCLIENT_HTTPS
#define USE_WEBCLIENT
```
(USE_BERRY_CRYPTO_RSA is new, my webcam based one was missing USE_WEBCLIENT, USE_WEBCLIENT_HTTPS?)


### Files:

#### [googleoauth.be](./googleoauth.be)
This provides the authorisation features.  Load the file into Berry.  Save your JSON key file to the TAS filesystem.

Usage:

Create an auth object using `var auth = google_oauth(<json filename>, <desired scope>)` e.g.:

`var auth = google_oauth("/google.json", "https://www.googleapis.com/auth/drive");`

The auth object is passed into a google_drive object to provide for getting an access token when needed.  Internally, the google_drive module calls auth.add_access_key(client) to add the auth header to a webclient instance.  A new access_token is only obtained when required, so an auth object can be long lived.  By default, 1 hour is requested on a token.

#### [gdrive.be](./gdrive.be)
This provides the Google Drive features.  Load the file into Berry.

Usage:

Create a gdrive object using `var gdrive = google_drive(auth)` 

To write a file to a folder which has been shared with your service account, you need the folderID (the number in the link when you look at the folder in google drive).  To write to a file, use `gdrive.write(folder_id, 'mytestfile.txt', "text text or bytes")`

To delete a file use `gdrive.delete(fileId)`

To list a folder `gdrive.readdir(nil || <folder ID>)` (could blow memory away?)

To get the folder(s) that a file is in `gdrive.getparents(fileid)`

To delete all files which belong to the service account, but are no longer referenced by a folder `gdrive.cleanservicefiles()` (will be slow, could blow memory away?).

Example:
```
var auth = google_oauth("/google.json", "https://www.googleapis.com/auth/drive");
var gdrive = google_drive(auth)
var resp = gdrive.write(folder_id, 'mytestfile.txt', "text text or bytes")
print(resp)
```

#### [gdrivetest.be](./gdrivetest.be)

A very simple complete example.  

May be broken from time to time...

#### [gdrivepics.be](./gdrivepics.be) 

A sample which requires my webcam driver, and then saves three pictures to google drive.

