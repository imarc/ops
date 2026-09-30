# Serving git worktrees through ops

## Goal

Serve a git worktree of an ops project at `<worktree>.<project>.OPS_DOMAIN`.
Example: the Paseo worktree `green-otter` of `amesbury-agency` is served at
`https://green-otter.amesbury-agency.imarc.io`.

Scope is serving only: nginx routing and the Apache docroot. The ops CLI,
dashboard, certs, and domain aliases are unchanged.

## Setup (user side)

1. Point Paseo's worktree root inside `OPS_SITES_DIR`, using a dot-prefixed
   folder, in `~/.paseo/config.json`:

   ```json
   { "worktrees": { "root": "/home/kevin/Code/.paseo-worktrees" } }
   ```

   The folder must be hidden (leading dot) so it is not treated as a project:
   `project-ls` (`ls -d */`) skips it, it gets no cert SAN, and no hostname
   can route to it because the nginx project-name pattern `[^.]+` never
   matches a leading dot.

2. In each project, commit a `paseo.json` so new worktrees are bootable:

   ```json
   {
     "worktree": {
       "setup": "cp \"$PASEO_SOURCE_CHECKOUT_PATH/.env\" .env\ncomposer install\nnpm ci"
     }
   }
   ```

   Copy `.env`; do not symlink it. An absolute symlink points at the host
   path of the main checkout, which does not exist inside the containers
   (the sites dir is mounted at `/var/www/html`).

3. Run `ops system install` to deploy the updated nginx and Apache files.

No new ops config options. No new mounts: worktrees live under
`OPS_SITES_DIR`, which nginx and every backend already mount at
`/var/www/html`.

## Routing

For host `green-otter.amesbury-agency.imarc.io`, the existing Lua yields
`name = "amesbury-agency"` and `full = "green-otter.amesbury-agency"`.

1. If `full` has exactly two labels (`^([^.]+)%.[^.]+$`), the first label is
   the worktree name. Deeper hosts (`a.green-otter.amesbury-agency`) are not
   checked as worktrees.
2. Read the first line of
   `/var/www/html/<name>/.git/worktrees/<worktree>/gitdir`. Git writes the
   worktree's absolute host path there, for example
   `/home/kevin/Code/.paseo-worktrees/068jttkj/green-otter/.git`.
   Strip the trailing `/.git`.
3. The host path must start with `OPS_SITES_DIR/`. Otherwise it is not mounted
   and is ignored. If it matches, the container path is
   `/var/www/html` + (host path without the `OPS_SITES_DIR` prefix).
4. On a match, the project path becomes the worktree's container path. If the
   worktree has a `.env`, it replaces the main project's `.env`. Otherwise the
   main project's `.env` is used. Backend, docroot, docroot check, and basic
   auth file all resolve against the worktree path.
5. If there is no match, behavior is unchanged: when `name ~= full` and
   `OPS_PROJECT_ALLOW_SUBDOMAINS` is not `"1"`, return 404. Otherwise serve the
   main project.

Serving a worktree does not require `OPS_PROJECT_ALLOW_SUBDOMAINS`.

The URL label is git's worktree entry name (the directory under
`.git/worktrees/`). It is usually the worktree folder's basename, but git adds
a numeric suffix on collisions (for example `green-otter1`).

HTTPS already works when the project existed at the last
`ops system refresh-certs`, because the cert includes
`*.<project>.OPS_DOMAIN` for every project.

## Changes

### `home/nginx/nginx.conf`

- Add `set $ops_project_path '';` with the other `set` directives.
- Replace the `-- subdomains` block (after `path` and `env` are set) with:

  ```lua
  -- worktrees: <worktree>.<project>.OPS_DOMAIN
  local worktree = full:match('^([^.]+)%.[^.]+$')
  local worktree_path = nil

  if worktree then
      local sites_dir = os.getenv('OPS_SITES_DIR')
      local file = io.open(path .. '/.git/worktrees/' .. worktree .. '/gitdir')

      if file then
          local dir = (file:read('*l') or ''):gsub('/%.git$', '')
          file:close()

          if dir:sub(1, #sites_dir + 1) == sites_dir .. '/' then
              worktree_path = '/var/www/html' .. dir:sub(#sites_dir + 1)
          end
      end
  end

  if worktree_path then
      path = worktree_path

      if is_file(path .. '/.env') then
          env = dotenv(path .. '/.env')
      end
  elseif name ~= full and env['OPS_PROJECT_ALLOW_SUBDOMAINS'] ~= "1" then
      ngx.exit(404)
      return
  end

  ngx.var.ops_project_path = path
  ```

- Add `proxy_set_header X-Ops-Project-Path $ops_project_path;`.

`OPS_SITES_DIR` is already passed to nginx and preserved by the `env`
directive. The `full` pattern only allows `[a-zA-Z0-9._-]`, so the worktree
label cannot contain `/` or `..`.

### `home/apache/set_docroot.lua`

Build the base path from the new header:

```lua
local path = r.headers_in['X-Ops-Project-Path']
    or ('/var/www/html/' .. r.headers_in['X-Ops-Project-Name'])
```

The fallback covers requests where the Lua returns before setting the path
(`name == 'ops'`). nginx omits a header whose value is empty. A
client-supplied `X-Ops-Project-Path` is overwritten by `proxy_set_header`. Every backend mounts this file from `OPS_HOME`, so no image
rebuild is needed.

### `README.md`

Add a "Serving git worktrees" section covering setup steps 1–3 and the URL
format. Also fix the stale `ops system regenerate-certs` reference under
`OPS_PROJECT_ALLOW_SUBDOMAINS` to `ops system refresh-certs`.

### `CHANGELOG.md`

Add one entry under the next version.

## Known limitations

- Worktrees for non-ops repos also land in `OPS_SITES_DIR/.paseo-worktrees`.
  That is harmless to ops.
- Inside a worktree, `ops project name` returns `.paseo-worktrees` instead of
  exiting 1. `ops shell`, `ops composer`, and `.env` / `ops-commands.sh`
  sourcing are not worktree-aware. That is out of scope.
- Existing worktrees under `~/.paseo/worktrees` are not served. Only worktrees
  created after the Paseo root change are.
- If the main project's `.git` is itself a file (the main checkout is a
  worktree), no lookup happens and the 404/subdomain fallback applies.

## Verification

1. Run `ops system install`, then create a Paseo worktree for a project.
2. Add a marker file to the worktree only. Check that
   `curl -k https://<wt>.<project>.imarc.io/<marker>` serves it.
3. `https://<project>.imarc.io` still serves the main checkout.
4. `https://bogus.<project>.imarc.io` returns 404, or serves main when
   `OPS_PROJECT_ALLOW_SUBDOMAINS=1`.
5. A worktree without `.env` is served using the main project's backend and
   docroot.
6. A plain project request (`<project>.imarc.io`) still gets the correct
   docroot through `X-Ops-Project-Path`, on at least two PHP backends.
