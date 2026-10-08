_names=()
_pids=()

# start NAME CMD...
# Starts a process. Logs get printed with the "$name> " prefix
start() {
    local name=$1; shift
    "$@" > >(sed -u "s/^/\x1B[2m$name>\x1B[0m /") 2>&1 &
    _names+=("$name")
    _pids+=($!)
}

# wait_for TIMEOUT CMD...
# Waits for the command to succeed in the given interval
wait_for() {
    local t=$1; shift
    for _ in $(seq $((t * 10))); do
        "$@" >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    echo "Timed out waiting for: $*"
    return 1
}

# Terminates all processes started with `start`
stop_all() {
    trap - INT TERM EXIT
    for ((i=${#_pids[@]} - 1; i >= 0; i--)); do
        kill -TERM "${_pids[i]}" 2>/dev/null
    done
    wait
}

# Exits when any child process ends
wait_for_jobs() {
    local pid rc name="<unknown>"
    wait -n -p pid "${_pids[@]}"
    rc=$?
    for i in "${!_pids[@]}"; do
        if [[ ${_pids[i]} == "$pid" ]]; then
            name=${_names[i]}
            break
        fi
    done
    echo "Process '$name' exited (status $rc); shutting down"
    return $rc
}

trap 'stop_all; exit 130' INT TERM
trap stop_all EXIT
