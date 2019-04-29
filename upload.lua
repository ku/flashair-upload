#!/usr/bin/env lua

LOGGER_HOST = "http://192.168.3.10/"
COMMAND = arg[0]

ENABLE_FILE_LOG = true

if (os.getenv("HOME") ~= nil ) then
  lfs = require 'lfs'
  platform = "osx"
  rootpath = "./DCIM"
else
  platform = "native"
  rootpath = "/DCIM"
end

function log(s)
  method = "GET"
  if (os.getenv("HOME") ~= nil ) then
    print(s)
  else
    b, c, h = fa.request(LOGGER_HOST..s, method)
  end
end

function debug(s)
end

function lastUploadedNo()
  if platform == "osx" then
    return 0
  end

  local body, status, headers = fa.request(LOGGER_HOST.."post/", "GET")
  local lastUploaded = tonumber(body)
  if lastUploaded then
    return tonumber(lastUploaded)
  else
    debug("failed to start "..tostring(status)..body)
    return nil
  end
end

function bootstrap()
  log("platform="..platform..COMMAND)
  local lastNo = lastUploadedNo()

  if lastNo then
    debug("lastNo.fetched."..tostring(lastNo))
    q = findPhotos(lastNo)
    photosToUpload = tableSort(q)

    for k, file in pairs(photosToUpload) do
      local dirId, photoId = string.match(file.name, '(%d%d%d).+(%d%d%d%d%d).JPG')
      if dirId ~= nil and photoId ~= nil then
        seqNo = tonumber(dirId) * 100000 + tonumber(photoId)

        if seqNo > lastNo then
          debug("uploading"..tostring(file.name))
          n = uploadFile(file.name)
          if n then
            lastNo = n
            debug('lastNo.updated'..tostring(lastNo))
          else
            debug('failed.exiting')
            return
          end
        else
          debug('done')
        end
      end
    end
  else
    debug('nil lastNo')
  end
end


function uploadFile(filePath)
    local boundary = '--bnfDxpKY69NKk'
    local headers = {}
    local place_holder = '<!--WLANSDFILE-->'

    headers['Connection'] = 'close'
    headers['Content-Type'] = 'multipart/form-data; boundary="'..boundary..'"'

    filename = string.gsub(filePath, '/', '_')

    local body = '--'..boundary..'\r\n'
        ..'Content-Disposition: form-data; name="source"; filename="'
        ..filename..'"\r\n'
        ..'Content-Type: image/jpeg\r\n\r\n'
        ..place_holder..'\r\n'
        .. '--' .. boundary .. '--\r\n'


    headers['Content-Length'] =
        lfs.attributes(filePath, 'size')
        + string.len(body)
        - string.len(place_holder)

    local args = {}
    args["url"] = LOGGER_HOST..'post/'
    args["method"] = "POST"
    args["headers"] = headers
    args["body"] = body
    args["file"] = filePath
    args["bufsize"] = 1460*10
    args["redirect"] = false
    local body, status, headers = fa.request(args)

    collectgarbage()
    if (status ~= 200) then
      return nil
    end

    return tonumber(body)
end

function findPhotos(lastSequenceNo)
  local n = 0
  local photos = {}

  for aDirectory in lfs.dir(rootpath) do
    local lastDirectory = math.floor(lastSequenceNo / 100000)
    local lastPhoto = lastSequenceNo % 100000
    local dirId = tonumber(aDirectory:sub(1, 3))

    if (dirId ~= nil and dirId >= lastDirectory) then
      for aFile in lfs.dir(rootpath .. "/"..aDirectory) do
        local filePath = rootpath .. "/"..aDirectory.."/"..aFile

        if (lfs.attributes(filePath, "mode") == "file") then
          local photoId = tonumber(aFile:sub(5, 8))
          local seq = dirId * 100000 + photoId
          local item = {}
          item.id = seq
          item.name = rootpath.."/"..aDirectory.."/"..aFile
          photos[seq] = item
        end
      end
    end
  end

  return photos
end

function tableSort(obj)
  local sortkey = {}
  local n = 0
  for k,v in pairs(obj) do
    n = n + 1
    sortkey[n] = v
  end

  table.sort(sortkey, function(a, b)
    return a.id < b.id
  end)
  return sortkey
end

bootstrap()
