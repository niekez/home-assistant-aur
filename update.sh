#!/bin/bash

set -e
LAST_VERSION=$(ruby -r "net/http" -r "uri" -r "json" -e 'uri = URI.parse("https://api.github.com/repos/home-assistant/home-assistant/releases"); response = Net::HTTP.get_response(uri); if response.code.to_i != 200 then puts response.code.inspect; exit(1); end; puts JSON.parse(response.body).first["name"]')

VERSION=$1
echo "Will update to ${VERSION:=$LAST_VERSION}"

sed -i -re "s/^pkgver=.*$/pkgver=$VERSION/" PKGBUILD
# Reset release to 1
sed -i -re "s/^pkgrel=.*$/pkgrel=1/" PKGBUILD

makepkg --verifysource || echo "Will now update checksums"

updpkgsums

makepkg --printsrcinfo > .SRCINFO

# install all dependencies
cat .SRCINFO |grep -E "\s(make)?depends" | cut -d= -f2- | xargs pacaur -S --needed --noedit

makepkg -si

echo "Finisedh building package"

sudo systemctl --no-pager status home-assistant

echo "Sleep 60sec to ensure everything is working good"

for i in {1..12}; do echo -n . ; sleep 5 ; done
sudo systemctl --no-pager status home-assistant


echo "You simply have to commit+push the changes"
