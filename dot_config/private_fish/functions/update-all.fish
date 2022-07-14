function update-all
sudo true
rate-mirrors --save=/tmp/ratemirrorlist arch --max-delay=43200
sudo mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo mv /tmp/ratemirrorlist /etc/pacman.d/mirrorlist
end
