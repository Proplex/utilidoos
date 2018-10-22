# bashrc for Docker wrapping

#
# Wrap the main docker command to support injected sub-commands
#
#  docker blame        List image layer sizes and what's responsible
#
#  bosh *              Hand off to the main docker binary
#
docker() {
    case ${1} in
    (blame)
        if [[ -n "$2" ]]; then
            docker history $2 --format "==> {{.Size}} {{.CreatedBy}}" --no-trunc
        fi
        return 0
        ;;

    (*)
        command docker "$@"
        return $?
        ;;
    esac
}
