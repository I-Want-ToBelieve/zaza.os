## mouse and keyboard input by evdev

```zsh
sudo -E virsh attach-device AtlasOS /home/i.want.to.believe/git.workspaces/dotfiles.workspaces/devos/qemu-kvm/AtlasOS/mouse-evdev.xml
sudo -E virsh attach-device AtlasOS /home/i.want.to.believe/git.workspaces/dotfiles.workspaces/devos/qemu-kvm/AtlasOS/keyboard-evdev.xml
```

## cdrom disk

```zsh
sudo -E virsh attach-disk AtlasOS /home/i.want.to.believe/git.workspaces/dotfiles.workspaces/devos/qemu-kvm/AtlasOS/cdrom-disk.xml
sudo -E virsh attach-disk AtlasOS /home/i.want.to.believe/git.workspaces/dotfiles.workspaces/devos/qemu-kvm/AtlasOS/nvme-2t-disk.xml
```

##
