#!/bin/sh

# Edit these variables to suit your environment.
HOSTS_REPO=https://github.com/sjnp/fake-host-lists.git
LOCAL_BRANCH=main
REMOTE_BRANCH=origin/main
HEADER="########### HOST NAMES FROM HOST REPO ###########"
FOOTER="#################################################"

# Backup the old host file
echo "Backup the current host file to ./old-hosts"
cp /etc/hosts ./old-hosts

# Delete all old hosts that generated by this script
echo "Deleting old hosts inside /etc/hosts that generated by this script ..."
START_LINE=$(grep -n "$HEADER" /etc/hosts | cut -d : -f1)
END_LINE=$(grep -n "$FOOTER" /etc/hosts | cut -d : -f1)
if [[ "$START_LINE" -ne 0 || "$END_LINE" -ne 0 ]]; then
  SED_EXP=$START_LINE","$END_LINE"d"
  sed -e $SED_EXP /etc/hosts | sudo tee /etc/hosts > /dev/null &&
    echo "Deleted genereted hosts successfully"
fi

# Check if host repo already exist or not.
# If the repo doesn't exist then clone it.
# Else check if the repo is up-to-date with the remote branch.
if [ ! -d "repo" ]; then
  mkdir repo
  echo "Cloning host repo ..."
  git clone "$HOSTS_REPO" ./repo && 
  cd "$_" && 
  echo "Cloned host repo successfully" || 
  { echo "Failed to clone host repo"; exit;}
else
  cd repo
  echo "Checking if host repo is up-to-date or not ..."
  git remote update
  LOCAL_HASH=$(git rev-parse $LOCAL_BRANCH)
  REMOTE_HASH=$(git rev-parse $REMOTE_BRANCH)

  # If host repo is not up-to-date, pull the remote branch 
  if [ ! $LOCAL_HASH = $REMOTE_HASH ] 
  then
    echo "The host repo need to be updated"
    echo "Pulling from the remote repo ..."
    git pull && 
      echo "Pull from the remote repo successfully" ||
      { echo "Failed to pull from the remote repo"; exit; }
  fi
  echo "The host repo is already up-to-date."
fi

echo "Adding new hosts to /etc/hosts"
echo $HEADER | sudo tee -a /etc/hosts > /dev/null
for filename in ./*; do
  cat "$filename" | sudo tee -a /etc/hosts > /dev/null
done
echo $FOOTER | sudo tee -a /etc/hosts > /dev/null
