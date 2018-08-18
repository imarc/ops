--[[
Set document root.
]]--

require 'apache2'

local docroots = {
    '/public',
    '/public_html',
    '/web',
    '/htdocs',
    '/docroot',
    ''
}

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function exists(path)
    local code = os.execute(('[ -e "%s" ]'):format(path))

    -- mod_lua shows different behavior with different
    -- versions. os.execute returns true/nil instead or
    -- 0/1. this snippet ensures the exit code is always an integer
    if code == true or code == nil then
        code = code == true and false or true
    end

    return code
end

function dotenv(path)
    local env = {}

    for line in io.lines(path .. '/.env') do
        local key, value = string.match(line, '^([^#][^=]+)=[\'"]?([^\'"]+)')
        if key then env[key] = value end
    end

    return env
end

function set_docroot(r)
    local path = r:ivm_get('ops-docroot-' .. r.hostname)

    if path != nil and exists(path) then
        r.filename = path .. r.uri
        r:set_document_root(path)
        return apache2.OK
    end

    -- print('here')

    local path = '/var/www/html/' .. r.hostname:match("^([^.]+)")
    local env = dotenv(path .. '/.env')

    if env['OPS_PROJECT_DOCROOT'] then
        local docroot = string.match(env['OPS_PROJECT_DOCROOT'], '^/?([^/]+)')
        if docroot then docroot = '/' .. docroot end

        r:ivm_set('ops-docroot-' .. r.hostname, path .. docroot)

        r.filename = path .. docroot .. r.uri
        r:set_document_root(path .. docroot)
        return apache2.OK
    end

    for k,docroot in ipairs(docroots) do
        local code = os.execute(('[ -e "%s%s" ]'):format(path, docroot))

        -- mod_lua shows different behavior with different
        -- versions. os.execute returns true/nil instead or
        -- 0/1. this snippet ensures the exit code is always an integer
        if code == true or code == nil then
            code = code == true and 0 or 1
        end

        if code == 0 then
            r.filename = path .. docroot .. r.uri
            r:set_document_root(path .. docroot)
            return apache2.OK
        end
    end

    return apache2.DECLINED
end
