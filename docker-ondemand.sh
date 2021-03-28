#!/bin/bash
# usage: docker-ondemand [OPTIONS] COMMAND

set -euf -o pipefail

DOCKER="/Applications/Docker.app/Contents/Resources/bin/docker"

docker_inactive() {
	count="$($DOCKER ps --quiet | wc -l)"
	if [ "$count" -ne 0 ]; then
		return 1
	fi

	count="$($DOCKER events --since "30m" --until 1s | wc -l)"
	if [ "$count" -ne 0 ]; then
		return 1
	fi

	return 0
}

docker_open() {
	if ! "$DOCKER" info &>/dev/null; then
		echo "Starting Docker" >&2
		open --background -a Docker
		while ! "$DOCKER" info &>/dev/null; do
			sleep 1
		done
	fi
}

docker_safe_quit() {
	if ! "$DOCKER" info &>/dev/null; then
		echo "Docker is not running" >&2
	elif docker_inactive; then
		echo "Quiting Docker" >&2
		osascript -e 'quit app "Docker"'
	else
		echo "Docker has been busy recently" >&2
		exit 1
	fi
}

if [ "${1-}" == "safe-quit" ]; then
	docker_safe_quit
else
	docker_open
	exec docker "$@"
fi
