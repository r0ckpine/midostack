#!/bin/bash -xe

# Copyright 2014 Midokura SARL
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create the dest dir in case it doesn't exist
# Github clone will fail to run otherwise
if [ ! -d $MIDONET_DIR ]; then
    echo "Creating midonet destination directory... $MIDONET_DIR"
    sudo mkdir -p $MIDONET_DIR
    sudo chmod -R 777 $DEST
fi

# Get MidoNet source and install
if [ ! -d "$MIDONET_SRC_DIR" ]; then
    git_clone $MIDONET_GIT_REPO $MIDONET_SRC_DIR $MIDONET_GIT_BRANCH
    if [ $? -gt 0 ]
    then
        echo $?
        echo "Exiting. Cloning MidoNet git repo $MIDONET_GIT_REPO (branch $MIDONET_GIT_BRANCH) failed, please check if environment variable MIDONET_GIT_REPO and MIDONET_GIT_BRANCH."
        exit 1
    fi
fi
cd $MIDONET_SRC_DIR && git submodule update --init

# Build midonet and produce jar files under build directories
build_midonet $MIDONET_SRC_DIR

# install midonet jars and command line tools
install_midonet $MIDONET_SRC_DIR

# install midonet-cli
# Clean up previous installation
sudo rm -rf /usr/local/bin/midonet-cli /usr/local/lib/python2.7/dist-packages/midonetclient*

# Install python module and midonet-cli
sudo apt-get install -y ncurses-dev libreadline-dev
sudo pip install -U webob readline httplib2
cd $MIDONET_CLIENT_DIR
sudo python setup.py develop

# Make sure to remove system lib dire in case it exists
if grep -qw /usr/lib/python2.7/dist-packages /usr/local/lib/python2.7/dist-packages/easy-install.pth; then
    echo "replacing /usr/local/lib/python2.7/dist-packages/easy-install.pth so it remove /usr/lib/python2.7/dist-packages"
    grep -v /usr/lib/python2.7/dist-packages /usr/local/lib/python2.7/dist-packages/easy-install.pth| sudo tee /usr/local/lib/python2.7/dist-packages/easy-install.pth
fi
