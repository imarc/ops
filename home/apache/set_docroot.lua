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

function set_docroot(r)
    local path = '/var/www/html/' .. r.hostname:match("^([^.]+)")

    for k,docroot in ipairs(docroots) do
        local code = os.execute(('[ -e "%s%s" ]'):format(path, docroot))

        -- mod_lua shows different behavior with different
        -- distributions. os.execute returns true/nil instead or
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
