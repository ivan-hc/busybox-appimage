#!/bin/sh

APP=busybox.static

# TEMPORARY DIRECTORY
mkdir -p tmp
cd ./tmp || exit 1

# DOWNLOAD APPIMAGETOOL
if ! test -f ./appimagetool; then
	wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool || exit 1
	chmod a+x ./appimagetool
	export PATH="$PWD":"${PATH}"
fi

# CREATE BUSYBOX APPIMAGES

_create_appimage(){
	PKGNAME=$(curl -Ls https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/"$ARCH_REF"/ | tr '">< ' '\n' | grep busybox-static | head -1)
	VERSION=$(echo $PKGNAME | grep -Eo "[0-9].*[0-9]")
	DL="https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/$PKGNAME"
	if wget --version | head -1 | grep -q ' 1.'; then
		wget -q --no-verbose --show-progress --progress=bar "$DL" -O "${a}${PKGNAME}" || exit 1
	else
		wget "$DL" || exit 1
	fi
	export arch="$a"
	curl -Ls "https://raw.githubusercontent.com/ivan-hc/portable2appimage/refs/heads/main/portable2appimage" | sh -s -- ./*.apk busybox.static "$VERSION" || exit 1
}

ARCHITECTURES="i686 x86_64 aarch64"
export UPINFO="$GITHUB_REPOSITORY_OWNER|Busybox-appimage|latest"
for a in $ARCHITECTURES; do
	if [ "$a" = i686 ]; then
		ARCH_REF="x86"
	else
		ARCH_REF="$a"
	fi
	mkdir -p "$a"
	#cp ./appimagetool ./"$a"/appimagetool 2>/dev/null
	cd "$a" || exit 1
	_create_appimage
	cd .. || exit 1
	mv ./"$arch"/*.AppImage* ./
done

# Create artifacts for direct links
for a in $ARCHITECTURES; do
	cp ./*"$a"*.AppImage ./busybox-"$a"-static
done

cd ..
mv ./tmp/*.AppImage* ./
mv ./tmp/busybox-*-static ./

