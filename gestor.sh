#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="hola-docker"
IMAGE_NAME="${PROJECT_NAME}:v1.0.0"
CONTAINER_NAME="${PROJECT_NAME}-container"
APP_PORT=8080
JAR_PATH="$SCRIPT_DIR/target/${PROJECT_NAME}-*.jar"

jar_exists() {
	local jar_files=("$SCRIPT_DIR"/target/"$PROJECT_NAME"-*.jar)
	if [[ -f "${jar_files[0]}" ]]; then
		JAR_PATH="${jar_files[0]}"
		return 0
	else
		return 1
	fi
}

docker_image_exists() {
	if command -v docker >/dev/null 2>&1; then
		if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
			return 0
		else
			return 1
		fi
	else
		return 1
	fi
}

check_prerequisites() {
	local commands=(java mvn docker)
	local command_name
	for command_name in "${commands[@]}"; do
		if command -v "$command_name" >/dev/null 2>&1; then
			printf '%s: available (%s)\n' "$command_name" "$(command -v "$command_name")"
		elif [[ "$command_name" == "mvn" && -x "$SCRIPT_DIR/mvnw" ]]; then
			printf 'mvn: available (wrapper: %s/mvnw)\n' "$SCRIPT_DIR"
		else
			printf '%s: not available\n' "$command_name"
		fi
	done
}

package_application() {
	printf 'Building executable JAR...\n'
	if (cd "$SCRIPT_DIR" && ./mvnw clean package -DskipTests); then
		if jar_exists; then
			printf 'Package completed. Generated JAR: %s\n' "$JAR_PATH"
		else
			printf 'Maven completed, but no JAR matching %s was found.\n' "$JAR_PATH"
			return 1
		fi
	else
		printf 'Packaging failed. Check the Maven output above.\n'
		return 1
	fi
}

build_docker_image() {
	if jar_exists; then
		:
	elif [[ -d "$SCRIPT_DIR/target" ]]; then
		printf 'Executable JAR not found. Select option 2 to package the application first.\n'
		return 1
	else
		printf 'Build directory not found. Select option 2 to package the application first.\n'
		return 1
	fi

	if ! command -v docker >/dev/null 2>&1; then
		printf 'docker: not available. Install Docker before building the image.\n'
		return 1
	fi

	printf 'Building Docker image %s...\n' "$IMAGE_NAME"
	if (cd "$SCRIPT_DIR" && docker build -t "$IMAGE_NAME" .); then
		printf 'Docker image %s built successfully.\n' "$IMAGE_NAME"
	else
		printf 'Docker image build failed. Check the Docker output above.\n'
		return 1
	fi
}

run_docker_container() {
	if ! command -v docker >/dev/null 2>&1; then
		printf 'docker: not available. Install Docker before running the container.\n'
		return 1
	fi

	if ! docker info >/dev/null 2>&1; then
		printf 'Docker daemon is not available. Start Docker and try again.\n'
		return 1
	fi

	if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
		printf 'Docker image %s not found. Build it with option 3 first.\n' "$IMAGE_NAME"
		return 1
	fi

	if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
		local container_running
		container_running=$(docker container inspect --format '{{.State.Running}}' "$CONTAINER_NAME")
		if [[ "$container_running" == "true" ]]; then
			local confirmation
			read -r -p "Container $CONTAINER_NAME is running. Stop and remove it before starting a new one? [y/N] " confirmation
			case "$confirmation" in
				y|Y|yes|YES|Yes)
					if ! docker stop "$CONTAINER_NAME" || ! docker rm "$CONTAINER_NAME"; then
						printf 'Could not stop and remove the existing container.\n'
						return 1
					fi
					;;
				*)
					printf 'Existing container left running; no new container was started.\n'
					return 0
					;;
			esac
		else
			printf 'Removing stopped container %s...\n' "$CONTAINER_NAME"
			if ! docker rm "$CONTAINER_NAME"; then
				printf 'Could not remove the existing container.\n'
				return 1
			fi
		fi
	fi

	if docker run -d --name "$CONTAINER_NAME" -p "$APP_PORT:$APP_PORT" "$IMAGE_NAME"; then
		printf 'Container started. Application: http://localhost:%s/hello\n' "$APP_PORT"
	else
		printf 'Could not start the Docker container. Check the Docker output above.\n'
		return 1
	fi
}

show_application_status() {
	if jar_exists; then
		local jar_size
		jar_size=$(du -h -- "$JAR_PATH" | cut -f1)
		printf 'JAR: available (%s, %s)\n' "$JAR_PATH" "$jar_size"
	else
		printf 'JAR: not found (expected %s)\n' "$JAR_PATH"
	fi

	if ! command -v docker >/dev/null 2>&1; then
		printf 'Docker image: unable to check (docker command not available)\n'
		printf 'Running application containers: unable to check (docker command not available)\n'
		return
	elif ! docker info >/dev/null 2>&1; then
		printf 'Docker image: unable to check (Docker daemon is not available)\n'
		printf 'Running application containers: unable to check (Docker daemon is not available)\n'
		return
	fi

	if docker_image_exists; then
		local image_created
		image_created=$(docker image inspect --format '{{.Created}}' "$IMAGE_NAME")
		printf 'Docker image: available (%s)\n' "$IMAGE_NAME"
		printf 'Image created: %s\n' "$image_created"
	else
		printf 'Docker image: not found (%s)\n' "$IMAGE_NAME"
	fi

	local running_containers
	running_containers=$(docker ps --filter "ancestor=$IMAGE_NAME" --format '{{.Names}}')
	if [[ -n "$running_containers" ]]; then
		printf 'Running application containers: yes (%s)\n' "${running_containers//$'\n'/, }"
	else
		printf 'Running application containers: no\n'
	fi
}

while true; do
	printf '\n%s manager\n' "$PROJECT_NAME"
	printf '1) Check system prerequisites\n'
	printf '2) Clean, compile, and package the application\n'
	printf '3) Build the Docker image\n'
    printf '4) Run the Docker container\n'
	printf '5) Show application status\n'
	printf '6) Exit\n'
	read -r -p 'Select an option: ' option

	if [[ "$option" == "1" ]]; then
		check_prerequisites
	elif [[ "$option" == "2" ]]; then
		package_application
	elif [[ "$option" == "3" ]]; then
		build_docker_image
	elif [[ "$option" == "4" ]]; then
		run_docker_container
	elif [[ "$option" == "5" ]]; then
		show_application_status
	elif [[ "$option" == "6" ]]; then
		printf 'Goodbye.\n'
		break
	else
		printf 'Invalid option. Select an option shown in the menu.\n'
	fi
done
