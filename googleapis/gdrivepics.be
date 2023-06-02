import crypto
import json
import string
import introspect

class google_oauth
  var google_json
  var access_token
  var jwt
  var refresh_time
  var jsonname
  
  
  def init(jsonname)
    self.refresh_time = 0
    self.jsonname = jsonname
    self.readjson()
  end
  
  # JWT requires base64url and not raw base64
  # see https://base64.guru/standards/base64url
  # input: string or bytes
  def base64url(v)
    import string
    if type(v) == 'string'   v = bytes().fromstring(v) end
    var b64 = v.tob64()
    # remove trailing padding
    b64 = string.tr(b64, '=', '')
    b64 = string.tr(b64, '+', '-')
    b64 = string.tr(b64, '/', '_')
    return b64
  end

  def readjson()
    # this is the key file downloaded from the google cloud console, assigned to a service account.
    # we need private_key and client_email
    var f = open(self.jsonname,"r")
    var json_data = f.read()
    f.close()
    self.google_json = json.load(json_data)
  end
  
  def create_google_jwt(duration)
    var key_map = self.google_json;
    var time = tasmota.rtc()

    # expirey in 1 hour
    var header = '{"alg":"RS256","typ":"JWT"}'
    var claim = '{"iss":"' .. key_map['client_email'] .. '",' ..
        '"scope":"https://www.googleapis.com/auth/drive",' ..
        '"aud":"https://oauth2.googleapis.com/token",' ..
        '"exp":' .. (time['utc']+duration) .. ',' ..
        '"iat":' .. time['utc'] .. '}' 

    var b64header=self.base64url(header)
    var b64claim=self.base64url(claim)
    # this is the first part of the JWT, xxx.yyy
    var body = b64header .. '.' .. b64claim

    # extract private key as bytes
    # split key into lines
    var private_key = key_map['private_key']
    while (private_key[-1] == '\n') private_key = private_key[0..-2] end
    var private_key_DER = bytes().fromb64(string.split(private_key, '\n')[1..-2].concat())

    # sign body
    var body_b64 = bytes().fromstring(body)
    var sign = crypto.RSA.rs256(private_key_DER, body_b64)
    var b64sign = self.base64url(sign)
    var jwt_token = body + '.' + b64sign
    print('created jwt')
    self.jwt = jwt_token;
    return jwt_token
  end

  def get_oath_token(duration)
    var jwt = self.create_google_jwt(duration)
    print('got jwt')
    var cl = webclient();
    print('got cl')
    
    cl.begin('https://oauth2.googleapis.com/token')
    var payload = 
      '{"grant_type":"urn:ietf:params:oauth:grant-type:jwt-bearer",' ..
      '"assertion":"' .. jwt .. '"}'
    var r = cl.POST(payload)
    if r == 200
      var s = cl.get_string()
      var jmap = json.load(s)
      print(jmap)
      self.access_token = jmap['access_token']
      var time = tasmota.rtc()
      self.refresh_time = time['utc'] + jmap['expires_in'] - 10
    end
  end

  def add_access_key(client)
    var time = tasmota.rtc()
    if time['utc'] > self.refresh_time
      self.get_oath_token(3600)
    end
    client.add_header('Authorization', 'Bearer ' .. self.access_token)
  end
end

var auth = google_oauth("/google.json");

print(auth)

#auth.get_oath_token("/google.json", 3600)

#print('got token ' .. auth.access_token[1..10])

class google_drive
  def post(folderid, name, bytesdata)
    # first, create the file, and read it's id
    var cl = webclient()
    cl.begin('https://www.googleapis.com/drive/v3/files?uploadType=media')
    print('begin file create')
    var body = '{"name":"' .. name .. '","parents":["' .. folderid .. '"]}'
    auth.add_access_key(cl)
    var r = cl.POST(body)
    if r == 200
      var s = cl.get_string();
      print('file created ' .. s)

      var id = json.load(s)['id']
      print('file id ' .. id)
      var clfile = webclient()
      var url = 'https://www.googleapis.com/upload/drive/v3/files/' ..id .. '?uploadType=media'
      print(url)
      clfile.begin(url)
      print('begin file upload')
      body = bytesdata
      auth.add_access_key(clfile)
      print('posting')
      r = clfile.PATCH(body)
      print('posted' .. r)
      if r == 200
        print('uploaded ' .. name)
      end
      var resp = clfile.get_string();
      print(resp)
    end
  end
end

var piccount = 0
var g = google_drive()
var folder_id = auth.google_json['folder_id']

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
    g.post(folder_id, 'frame' .. piccount .. '.jpeg', b)
    piccount = piccount + 1
  else 
    print('no picture')
  end
end

uploadPicNow()
uploadPicNow()
uploadPicNow()
