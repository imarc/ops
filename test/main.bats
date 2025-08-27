#!/usr/bin/env bats


@test "valid syntax" {
    bash -n ops.sh
}

@test "valid version" {
    [[ "$(bash ops.sh version)" =~ "ops version " ]]
}

@test "valid help" {
    [[ "$(bash ops.sh help)" =~ "Usage: ops <command>" ]]
}

@test "services successfully started" {
    bash ops.sh start

    [[ -z "$(bash ops.sh ps | grep Exit)" ]]
}

@test "services successfully stopped" {
    bash ops.sh stop

    [[ -z "$(bash ops.sh ps | grep Up)" ]]
}
