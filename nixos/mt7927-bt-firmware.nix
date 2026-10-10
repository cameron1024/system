# MediaTek MT7927 (MT6639) Bluetooth firmware.
#
# The btusb/btmtk driver support is upstream (7.1+), but the firmware blob
# isn't in linux-firmware yet: MR !946 was closed pending a MediaTek-submitted
# MR. This is the blob from that MR (extracted from ASUS's Windows driver
# package); the hash matches the one published by other users. Drop this once
# linux-firmware ships mediatek/mt7927/BT_RAM_CODE_MT6639_2_1_hdr.bin.
{pkgs, ...}: let
  rev = "77ad2a92acf2ac3e5ea47432b43d925ff99db909";
  name = "BT_RAM_CODE_MT6639_2_1_hdr.bin";
  blob = pkgs.fetchurl {
    url = "https://gitlab.com/jetm/linux-firmware/-/raw/${rev}/mediatek/mt7927/${name}";
    hash = "sha256-ZpxcmaDFnIXBKF09G4sxkVwtMTQaIkT07dy/1g/7vHY=";
  };
in {
  hardware.firmware = [
    (pkgs.runCommand "mt7927-bt-firmware" {} ''
      install -Dm444 ${blob} $out/lib/firmware/mediatek/mt7927/${name}
    '')
  ];
}
