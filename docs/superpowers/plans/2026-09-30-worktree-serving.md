# Worktree Serving Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Serve a git worktree of an ops project at `<worktree>.<project>.OPS_DOMAIN` when the worktree lives inside `OPS_SITES_DIR`.

**Architecture:** The nginx rewrite Lua reads `<project>/.git/worktrees/<wt>/gitdir` to find the worktree's host path. It keeps the path only if it is under `OPS_SITES_DIR`, maps it to `/var/www/html/...`, and uses it as the project path. A new `X-Ops-Project-Path` header carries that path to Apache's `set_docroot.lua`.

**Tech Stack:** bash, OpenResty (nginx + Lua 5.1/LuaJIT), Apache mod_lua, Docker.

**Spec:** `docs/superpowers/specs/2026-09-30-worktree-serving-design.md`

## Global Constraints

- No new ops config options and no new mounts. Worktrees must live under `OPS_SITES_DIR`, which is already mounted at `/var/www/html`.
- Only a host of exactly `<worktree>.<project>` (two labels before `OPS_DOMAIN`) is checked as a worktree.
- The gitdir host path must start with `OPS_SITES_DIR .. '/'` or it is ignored.
- A worktree's `.env` replaces the main project's `.env` only when it exists.
- Without a worktree match, the existing `OPS_PROJECT_ALLOW_SUBDOMAINS` / 404 behavior is unchanged.
- Serving a worktree does not require `OPS_PROJECT_ALLOW_SUBDOMAINS`.
- `set_docroot.lua` falls back to `'/var/www/html/' .. X-Ops-Project-Name` when `X-Ops-Project-Path` is absent.
- Scope is serving only: no changes to `ops.sh`, the CLI, the dashboard, certs, or domain aliases. The user handles the Paseo/`paseo.json` setup themselves.

## Review Focus

- A gitdir pointing outside `OPS_SITES_DIR`, including a lookalike prefix such as `/home/x/Sites-evil`, must be ignored and fall through to 404. Covered by `outside` and `evil` in Task 1.
- A worktree with no `.env` must use the main project's backend and docroot. Covered by `blue`.
- A client-sent `X-Ops-Project-Path` header must not change the docroot. Covered by the spoof check.
- A deeper host (`a.green.main`) must not be treated as a worktree. Covered by `a.green.main`.
- On a project with `OPS_PROJECT_ALLOW_SUBDOMAINS=1`, an unknown subdomain must still serve the main project. Covered by `bogus.subs`.

---

### Task 1: Isolated integration harness

**Files:**
- Create: `tests/worktrees.sh`

**Interfaces:**
- Consumes: `home/nginx/nginx.conf`, `home/nginx/errors/`, `home/apache/{000-default.conf,apache2.conf,configure,set_docroot.lua}`, `VERSION`, and local Docker images `openresty/openresty:1.13.6.2-stretch-fat` and `imarcagency/ops-apache-php85:<VERSION>`.
- Produces: `tests/worktrees.sh`. It exits 0 when every check passes, otherwise it exits 1 and prints one `FAIL` line per failed check. Task 2 runs it.

The harness runs its own containers on a private Docker network with a fixtures dir. It never touches the running ops containers. `OPS_SITES_DIR` is set to a fake host path (`/home/ops-test/Sites`). The Lua only compares it as a string, while the fixtures are mounted at `/var/www/html`.

- [ ] **Step 1: Write the harness**

Create `tests/worktrees.sh`:

```bash
#!/usr/bin/env bash
#
# Integration test for serving git worktrees at <worktree>.<project>.OPS_DOMAIN.
# Runs its own nginx and apache-php85 containers on a private network, so it
# does not touch a running ops install.
#
# Usage: tests/worktrees.sh

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
version="$(cat "$root/VERSION")"
prefix="ops-worktree-test-$$"
sites_dir="/home/ops-test/Sites" # pretend host path; the Lua only compares it as a string
fixtures="$(mktemp -d)"
failures=0

cleanup() {
    docker rm -f "$prefix-nginx" "$prefix-backend" >/dev/null 2>&1 || true
    docker network rm "$prefix" >/dev/null 2>&1 || true
    rm -rf "$fixtures"
}
trap cleanup EXIT

page() {
    mkdir -p "$(dirname "$1")"
    echo "$2" > "$1"
}

worktree() {
    local project="$1" name="$2" gitdir="$3"
    mkdir -p "$fixtures/$project/.git/worktrees/$name"
    echo "$gitdir" > "$fixtures/$project/.git/worktrees/$name/gitdir"
}

# main: docroot web/ from its .env
page "$fixtures/main/.env" "OPS_PROJECT_DOCROOT=web"
page "$fixtures/main/web/index.html" "main"

# green: worktree with its own .env (docroot public/)
worktree main green "$sites_dir/.wt/abc/green/.git"
page "$fixtures/.wt/abc/green/.env" "OPS_PROJECT_DOCROOT=public"
page "$fixtures/.wt/abc/green/public/index.html" "green"

# blue: worktree without .env, uses main's docroot (web/)
worktree main blue "$sites_dir/.wt/def/blue/.git"
page "$fixtures/.wt/def/blue/web/index.html" "blue"

# gitdirs outside OPS_SITES_DIR are ignored
worktree main outside "/somewhere/else/outside/.git"
worktree main evil "$sites_dir-evil/evil/.git"

# subs: allows subdomains, default docroot (public/)
page "$fixtures/subs/.env" "OPS_PROJECT_ALLOW_SUBDOMAINS=1"
page "$fixtures/subs/public/index.html" "subs"

chmod -R a+rX "$fixtures"

docker network create "$prefix" >/dev/null

docker run -d --name "$prefix-backend" --network "$prefix" --network-alias backend \
    -e APACHE_UID="$(id -u)" \
    -e APACHE_GID="$(id -g)" \
    -e OPS_ENABLED=1 \
    -v "$root/home/apache/000-default.conf:/etc/apache2/sites-enabled/000-default.conf" \
    -v "$root/home/apache/apache2.conf:/etc/apache2/apache2.conf" \
    -v "$root/home/apache/configure:/usr/local/bin/docker-configure" \
    -v "$root/home/apache/set_docroot.lua:/etc/apache2/set_docroot.lua" \
    -v "$fixtures:/var/www/html" \
    "imarcagency/ops-apache-php85:$version" >/dev/null

docker run -d --name "$prefix-nginx" --network "$prefix" -p 127.0.0.1::80 \
    -e OPS_DOMAIN=ops.test \
    -e OPS_SITES_DIR="$sites_dir" \
    -e OPS_DEFAULT_BACKEND=backend \
    -e OPS_DEFAULT_DOCROOT=public \
    -v "$root/home/nginx/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf" \
    -v "$root/home/nginx/errors:/var/www/errors" \
    -v "$fixtures:/var/www/html" \
    openresty/openresty:1.13.6.2-stretch-fat >/dev/null

port="$(docker port "$prefix-nginx" 80/tcp | head -1 | sed 's/.*://')"

# wait for both containers to serve the main project
for _ in $(seq 1 30); do
    if [[ "$(curl -s -H 'Host: main.ops.test' "http://127.0.0.1:$port/")" == main ]]; then
        break
    fi
    sleep 1
done

# expect HOST STATUS BODY [CURL_ARGS...]; an empty BODY means any body
expect() {
    local host="$1" status="$2" body="$3"
    shift 3

    local out
    out="$(curl -s -w '\n%{http_code}' -H "Host: $host" "$@" "http://127.0.0.1:$port/")"

    local got_status="${out##*$'\n'}"
    local got_body="${out%$'\n'*}"
    got_body="${got_body%$'\n'}" # index.html ends with a newline

    if [[ "$got_status" == "$status" && ( -z "$body" || "$got_body" == "$body" ) ]]; then
        echo "ok   $host $*"
    else
        echo "FAIL $host $*: expected $status '$body', got $got_status '$got_body'"
        failures=$((failures + 1))
    fi
}

expect main.ops.test 200 main
expect subs.ops.test 200 subs
expect bogus.subs.ops.test 200 subs
expect bogus.main.ops.test 404 ""
expect green.main.ops.test 200 green
expect blue.main.ops.test 200 blue
expect outside.main.ops.test 404 ""
expect evil.main.ops.test 404 ""
expect a.green.main.ops.test 404 ""
expect main.ops.test 200 main -H "X-Ops-Project-Path: /var/www/html/subs"

if (( failures > 0 )); then
    echo "$failures check(s) failed"
    exit 1
fi

echo "all checks passed"
```

- [ ] **Step 2: Make it executable and run it against the current code**

Run: `chmod +x tests/worktrees.sh && tests/worktrees.sh`

Expected: exit 1 with exactly two failures:

```
FAIL green.main.ops.test : expected 200 'green', got 404 '...'
FAIL blue.main.ops.test : expected 200 'blue', got 404 '...'
2 check(s) failed
```

All other checks print `ok`. If `main.ops.test` fails, the harness itself is broken, for example a container that didn't start or a permissions problem. Debug with `docker logs ops-worktree-test-<pid>-nginx` (drop the `trap` temporarily to keep the containers) before continuing.

- [ ] **Step 3: Commit**

```bash
git add tests/worktrees.sh
git commit -m "Add integration harness for serving git worktrees"
```

---

### Task 2: Worktree routing in nginx and Apache

**Files:**
- Modify: `home/nginx/nginx.conf` (the `set` directives at `:39-45`, the subdomain block at `:124-131`, and the proxy headers at `:167-169`)
- Modify: `home/apache/set_docroot.lua:8`

**Interfaces:**
- Consumes: `tests/worktrees.sh` from Task 1.
- Produces: the nginx variable `$ops_project_path` and the request header `X-Ops-Project-Path: <container path of the project or worktree>`, read by `set_docroot.lua`.

- [ ] **Step 1: Add the `$ops_project_path` variable**

In `home/nginx/nginx.conf`, replace:

```nginx
            set $ops_project_name '';
```

with:

```nginx
            set $ops_project_name '';
            set $ops_project_path '';
```

- [ ] **Step 2: Replace the subdomain block with worktree resolution**

In `home/nginx/nginx.conf`, replace:

```lua
                local path = '/var/www/html/' .. name
                local env = dotenv(path .. '/.env')

                -- subdomains
                if name ~= full and env['OPS_PROJECT_ALLOW_SUBDOMAINS'] ~= "1" then
                    ngx.exit(404)
                    return
                end
```

with:

```lua
                local path = '/var/www/html/' .. name
                local env = dotenv(path .. '/.env')

                -- worktrees: <worktree>.<project>.OPS_DOMAIN, when git records
                -- the worktree inside OPS_SITES_DIR
                local sites_dir = os.getenv('OPS_SITES_DIR')
                local worktree = full:match('^([^.]+)%.[^.]+$')
                local worktree_path = nil

                if worktree and sites_dir then
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
                    -- subdomains
                    ngx.exit(404)
                    return
                end

                ngx.var.ops_project_path = path
```

The later backend, docroot (`is_dir(path .. '/' .. ...)`) and basic auth code already uses `path` and `env`, so it needs no change. The parentheses around `gsub` drop its second return value.

- [ ] **Step 3: Send the path header**

In `home/nginx/nginx.conf`, replace:

```nginx
            proxy_set_header X-Ops-Project-Name $ops_project_name;
```

with:

```nginx
            proxy_set_header X-Ops-Project-Name $ops_project_name;
            proxy_set_header X-Ops-Project-Path $ops_project_path;
```

- [ ] **Step 4: Read the header in Apache**

In `home/apache/set_docroot.lua`, replace:

```lua
    local path = '/var/www/html/' .. r.headers_in['X-Ops-Project-Name']
```

with:

```lua
    local path = r.headers_in['X-Ops-Project-Path']
        or ('/var/www/html/' .. r.headers_in['X-Ops-Project-Name'])
```

The fallback covers requests where the nginx Lua returns before setting the path (`name == 'ops'`). nginx does not send headers with empty values.

- [ ] **Step 5: Syntax-check the Lua**

Run: `luajit -bl home/apache/set_docroot.lua >/dev/null && echo ok`
Expected: `ok`

Run: `docker run --rm -v "$PWD/home/nginx/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf" openresty/openresty:1.13.6.2-stretch-fat openresty -t`
Expected: `... syntax is ok` and `... test is successful`. This does not compile the Lua in the rewrite block. Step 6 covers that.

- [ ] **Step 6: Run the harness**

Run: `tests/worktrees.sh`
Expected: every line starts with `ok`, followed by `all checks passed`, and the exit code is 0.

- [ ] **Step 7: Commit**

```bash
git add home/nginx/nginx.conf home/apache/set_docroot.lua
git commit -m "Serve git worktrees at <worktree>.<project>.OPS_DOMAIN"
```

---

### Task 3: Docs

**Files:**
- Modify: `README.md` (the `OPS_PROJECT_ALLOW_SUBDOMAINS` comment at `:90-91`, plus a new section before `## Global Configuration` at `:96`)
- Modify: `CHANGELOG.md` (a new `## [Unreleased]` section above `## [0.18.0]`)

**Interfaces:**
- Consumes: the behavior shipped in Task 2.
- Produces: user docs only.

- [ ] **Step 1: Fix the stale cert command**

In `README.md`, replace:

```
    # may require 'ops system regenerate-certs' for HTTPS
```

with:

```
    # may require 'ops system refresh-certs' for HTTPS
```

- [ ] **Step 2: Add the worktree section**

In `README.md`, insert this section immediately before `## Global Configuration`:

````markdown
## Serving Git Worktrees

A git worktree of a project is served at `<worktree>.<project>.imarc.io` when
the worktree's directory is inside `OPS_SITES_DIR`. Ops finds it through the
main checkout's `.git/worktrees/<worktree>/gitdir`, so any tool that creates
worktrees works. `<worktree>` is git's name for the worktree, which is usually
its directory name.

Keep worktrees in a hidden folder so ops doesn't list that folder as a project,
for example `~/Sites/.worktrees`. For [Paseo](https://paseo.sh), set
`worktrees.root` in `~/.paseo/config.json`:

    { "worktrees": { "root": "/home/you/Sites/.worktrees" } }

The worktree's `.env` is used if it has one, otherwise the main project's.
Worktrees don't include untracked files, so copy `.env` and install
dependencies after creating one. Copy `.env`; don't symlink it, because the
symlink target doesn't exist inside the containers. With Paseo, you can do
this in `paseo.json`:

    {
      "worktree": {
        "setup": "cp \"$PASEO_SOURCE_CHECKOUT_PATH/.env\" .env\ncomposer install\nnpm ci"
      }
    }

HTTPS works for any project that existed at the last `ops system refresh-certs`.

````

- [ ] **Step 3: Add the changelog entry**

In `CHANGELOG.md`, insert above `## [0.18.0] - 2026-09-29`:

```markdown
## [Unreleased]

### Added
- Git worktrees inside `OPS_SITES_DIR` are served at `<worktree>.<project>.OPS_DOMAIN`

```

- [ ] **Step 4: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "Document serving git worktrees"
```
