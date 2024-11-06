cwd=$(pwd)
dir=$(pwd)
while [[ $dir != "/" ]]
do
  workspace_file="$dir/WORKSPACE"

  if [[ -f $workspace_file ]]
  then
    break
  fi

  cd $dir/..
  dir=$(pwd)
done

cd $cwd

if [[ $dir == "/" ]]
then
  echo "could not find workspace root directory."
  exit 1
fi

mounts=("$HOME:$HOME" "/var/run/docker.sock:/var/run/docker.sock" "/tmp:/tmp")

if [[ -n "$SSH_AUTH_SOCK" ]]
then
  auth_sock=$(readlink -f $SSH_AUTH_SOCK)
  if [[ $? -eq 0 ]]
  then
    mounts+=("$auth_sock:$auth_sock")
  fi
fi

directory_hash=$(echo -n "$dir" | sha1sum | head -c 40)

if [[ "$1" == "kill" ]]
then
  docker stop bazel_${directory_hash}
  exit
fi

docker ps | grep -q "bazel_${directory_hash}"
if [[ $? -ne 0 ]]
then
  docker run \
    --network host \
    $(printf -- '-v %s ' "${mounts[@]}") \
    -w $dir \
    --name bazel_${directory_hash} \
    --rm \
    --privileged \
    --add-host dev:127.0.0.1 \
    --add-host dev.local:127.0.0.1 \
    -d \
    ghcr.io/tobiaskohlbau/bazel:latest
fi


envs=('SSH_AUTH_SOCK' "DISPLAY=unix$DISPLAY")
if [[ -e .envrc ]]
then
  while read line || [[ -n $line ]]
  do
   envs+=($(echo "$line" | sed 's/export //g' | cut -d '=' -f1 ))
  done <<< $(cat .envrc | grep -v '^#' | grep -v '^$' | grep "export")
fi

command="bazel"
if [[ "$0" == *ibazel ]]
then
  command="ibazel"
fi

if [[ -t 0 ]]
then
  tty="--tty"
fi

docker exec --interactive $tty --workdir $dir $(printf -- '-e %s ' "${envs[@]}") bazel_$directory_hash $command "$@"
