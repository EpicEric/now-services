# now-services: A collection of now-compatible services
# Copyright (C) 2026 Eric Rodrigues Pires
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
# more details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

_names=()
_commands=()
_pids=()

# Helper function to spawn a child command. Logs get printed with the "$name> " prefix.
# Call with:
#   _now_spawn INDEX
_now_spawn() {
    local i=$1 name=${_names[$1]}
    eval "${_commands[i]}" > >(sed -u "s/^/\x1B[2m$name>\x1B[0m /") 2>&1 &
    _pids[i]=$!
}

# Starts a process.
# Call with:
#   now_start NAME CMD...
now_start() {
    local name=$1; shift
    _names+=("$name")
    _commands+=("$(printf '%q ' "$@")")
    _now_spawn $(( ${#_names[@]} - 1 ))
}

# Waits for the command to succeed in the given interval
# Call with:
#   now_wait_for TIMEOUT CMD...
now_wait_for() {
    local t=$1; shift
    for _ in $(seq $((t * 10))); do
        "$@" >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    echo "Timed out waiting for: $*"
    return 1
}

# Terminates all processes started with `start`
# Call with:
#   _now_stop_all
_now_stop_all() {
    trap - INT TERM EXIT
    for ((i=${#_pids[@]} - 1; i >= 0; i--)); do
        kill -TERM "${_pids[i]}" 2>/dev/null
    done
    wait
}

# Exits when any child process ends
# Call with:
#   now_wait_for_jobs
now_wait_for_jobs() {
    local pid= rc=0
    wait -n -p pid "${_pids[@]}" || rc=$?
    for i in "${!_pids[@]}"; do
        if [[ ${_pids[i]} == "$pid" ]]; then
            echo "Process '${_names[i]}' exited (status $rc); shutting down..."
            return $rc
        fi
    done
}

# Restarts any child process that terminates
# Call with:
#   now_wait_and_restart
now_wait_and_restart() {
    local pid= rc=0
    while true; do
        wait -n -p pid "${_pids[@]}" || rc=$?
        for i in "${!_pids[@]}"; do
            if [[ ${_pids[i]} == "$pid" ]]; then
                echo "Process '${_names[i]}' exited (status $rc); restarting..."
                sleep 1
                _now_spawn "$i"
                break
            fi
        done
    done
}

trap '_now_stop_all; exit 130' INT TERM
trap _now_stop_all EXIT
