## Files in this folder relate to the use of Google APIs from Tasmota.

From informaiton gleaned from [here](https://medium.com/@nschairer/automating-google-drive-uploads-with-google-drive-api-curl-196989ffb6ce) we find that you can authorise access to google APIs using a service account.

With a focus on wanting to upload images to a folder in my personal Google Drive, I persued this.  Following the link above, first you create a Service account in the Google cloud console, then share a folder from your personal drive with the service account email.  Then from the service account, add an API key, and download the JSON file.

I stored this json file in the Tasmota filesystem.  From the content of the JSON, we create a JWT, and sign it with one of the keys in the JSON file (thankyou to @s-hadinger for adding the required signing features in latest dev branch).  This JWT is then used to request an access token from google, with which you can then access the APIs.

The google API documentation is not great - it's quite hard to find out how to use it without a libarary.

[gdrivepics.be](./gdrivepics.be) is the result - a couple of classes for google authorisation, and for posting a file to google, and a simple example of using them to send photos from (my branch) webcam.


