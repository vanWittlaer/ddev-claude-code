#!/usr/bin/env bats

# Bats tests for the ddev-claude-code add-on.
# Run with:  bats ./tests/test.bats
# Requires:  ddev + bats-core installed on the host.

setup() {
  set -eu -o pipefail
  export DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-claude-code"
  export TESTDIR=$(mktemp -d -t "${PROJNAME}-XXXXXX")
  export DDEV_NONINTERACTIVE=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name="${PROJNAME}" --project-type=php
}

teardown() {
  set -eu -o pipefail
  cd "${TESTDIR}" || true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  [ -n "${TESTDIR}" ] && rm -rf "${TESTDIR}"
}

health_checks() {
  # The CLI must be installed and executable inside the web container.
  ddev exec "claude --version"
  # The host command wrapper must be wired up.
  ddev exec "which claude"
}

@test "install from directory and verify CLI is present" {
  set -eu -o pipefail
  cd "${TESTDIR}"
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  ddev add-on get "${DIR}"
  ddev restart >/dev/null
  health_checks
}

@test "install from release and verify CLI is present" {
  set -eu -o pipefail
  cd "${TESTDIR}"
  echo "# ddev add-on get vanWittlaer/ddev-claude-code with project ${PROJNAME} in $(pwd)" >&3
  ddev add-on get vanWittlaer/ddev-claude-code
  ddev restart >/dev/null
  health_checks
}
