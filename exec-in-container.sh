#!/bin/bash
# inspired ruoghly by: https://github.com/vishnubob/wait-for-it/blob/master/wait-for-it.sh
help()
{
    echo "Usage: exec-in-container <container_name> -- <command...>"
    echo
    echo "<container_name>"
    echo "    exepected started container in the app, named in 'docker-compose.yml' by 'container_name attribute"
    echo "    Example: npns_gateway"
    echo "<command...>"
    echo "    Any operation executed in context of container (WARNING: no validation performed)"
    echo "    Example: 'npm run orm -- migration:generate -c account -n NewMigration'"
}
container_name=
should_run_as_root=
inner_command=
while [[ $# -gt 0 ]]
do
    case "$1" in
        --root)
        should_run_as_root=true
        shift
        ;;
        --)
        shift
        inner_command=$@
        break;;
        *)
        if [ "$container_name" ]; then
            help
            exit 1
        fi
        container_name="$1"
        shift
        ;;
    esac
done
# TODO start containers here, in case they're not running

echo "Executing command '$inner_command'"
if [ $should_run_as_root ]; then
    sudo docker-compose up -d
    echo "Running with --root flag"
    sudo docker exec -it $container_name $inner_command    
else
    docker-compose up -d
    docker exec -it $container_name $inner_command
fi

