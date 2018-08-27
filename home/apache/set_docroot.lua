--[[
Set document root.
]]--

require 'apache2'

function set_docroot(r)
    local path = '/var/www/html/' .. r.hostname:match("^([^.]+)")

    local docroot = r.headers_in['X-Ops-Project-Docroot'] or ''
    docroot = docroot:gsub('^/+', ''):gsub('/+', '/')

    if docroot then
        docroot = '/' .. docroot
    end

    r.filename = path .. docroot .. r.uri
    r:set_document_root(path .. docroot)
    return apache2.OK
end
