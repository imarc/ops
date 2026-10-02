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
worktree main trav "$sites_dir/../../../etc/.git"

# rel: relative gitdir (git worktree.useRelativePaths), relative to the
# folder holding the gitdir file
worktree main rel "../../../../.wt/ghi/rel/.git"
page "$fixtures/.wt/ghi/rel/web/index.html" "rel"

# relative gitdirs that leave the sites dir are ignored
worktree main reltrav "../../../../../../etc/.git"

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
    -e OPS_SITES_DIR="$sites_dir/" \
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
expect trav.main.ops.test 404 ""
expect rel.main.ops.test 200 rel
expect reltrav.main.ops.test 404 ""
expect "foo~bar.ops.test" 404 ""
expect "x.foo~bar.ops.test" 404 ""
expect a.green.main.ops.test 404 ""
expect main.ops.test 200 main -H "X-Ops-Project-Path: /var/www/html/subs"

if (( failures > 0 )); then
    echo "$failures check(s) failed"
    exit 1
fi

echo "all checks passed"
