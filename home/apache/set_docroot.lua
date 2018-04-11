--[[
    Simple mass vhost script
    This example will check a map for a virtual host and rewrite filename and
    document root accordingly.
]]--

require 'apache2'

local docroots = {
    '/public',
    '/public_html',
    '/web',
    '/htdocs',
    '/docroot'
}

function set_docroot(r)
    local path = '/var/www/html/' .. r.hostname:match("^([^.]+)")

    for k,docroot in ipairs(docroots) do
        if os.execute(('[ -e "%s%s" ]'):format(path, docroot)) == 0 then
            r.filename = path .. docroot .. r.uri
            r:set_document_root(path .. docroot)
            return apache2.OK
        end
    end

    return apache2.DECLINED
end
