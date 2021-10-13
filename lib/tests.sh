#!/bin/bash


# test for the function to swap in a new uuid or partuuid
test_replace_uuid_in_cmdline(){

  pr_header "test replacing uuid/partuuid in cmdline.txt"

  tmpfile1=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile2=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile3=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile4=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile5=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile6=$(mktemp /tmp/cmdline_test.XXXXXX)

  new_partuuid="aabbccdd-03"
  new_uuid="e10a8a6e-2b7a-11ec-9a3f-001fb5278d0c"

  echo "console=serial0,115200 console=tty1 root=PARTUUID=13abc512-02 rootfstype=ext4 elevator=deadline fsck.repair=yes" > $tmpfile1

  echo "console=serial0,115200 console=tty1 root=UUID=1c92521c-4882-4f09-ac33-fb0a12086a7e rootfstype=ext4 elevator=deadline fsck.repair=yes" > $tmpfile2

  echo "console=serial0,115200 console=tty1 root=PARTUUID=${new_partuuid} rootfstype=ext4 elevator=deadline fsck.repair=yes" > $tmpfile3

  echo "console=serial0,115200 console=tty1 root=UUID=${new_uuid} rootfstype=ext4 elevator=deadline fsck.repair=yes" > $tmpfile4

  # cat $tmpfile1
  sed -E "s|(root=PARTUUID)=([^[:space:]]+)|root=PARTUUID=$new_partuuid|" $tmpfile1 > $tmpfile5

  # cat $tmpfile2
  sed -E "s|(root=UUID)=([^[:space:]]+)|root=UUID=$new_uuid|" $tmpfile2 > $tmpfile6

  pr_h3 "cmp compare PARTUUID"
  cmp $tmpfile3 $tmpfile5 || {
    echo "didn't match"
    cat $tmpfile3
    cat $tmpfile5
    exit 1
  }

  pr_h3 "cmp compare UUID"
  cmp $tmpfile4 $tmpfile6 || {
    echo "didn't match"
    cat $tmpfile4
    cat $tmpfile6
    exit 1
  }

  # cat $tmpfile3
  # cat $tmpfile4

  rm "$tmpfile1"
  rm "$tmpfile2"
  rm "$tmpfile3"
  rm "$tmpfile4"
  rm "$tmpfile5"
  rm "$tmpfile6"
}

# test for the function to swap in a new uuid or partuuid
test_replace_uuid_in_cmdline(){

  pr_header "test replacing uuid/partuuid in fstab"

  tmpfile1=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile2=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile3=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile4=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile5=$(mktemp /tmp/cmdline_test.XXXXXX)
  tmpfile6=$(mktemp /tmp/cmdline_test.XXXXXX)

cat << EOF > $tmpfile1
proc            /proc           proc    defaults          0       0
PARTUUID=9730496b-01  /boot           vfat    defaults          0       2
PARTUUID=9730496b-02  /               ext4    defaults,noatime  0       1
EOF



  fixup_fstab $tmpfile1 xxx  xxx2 yyy1 yyy2


  rm "$tmpfile1"
  rm "$tmpfile2"
  rm "$tmpfile3"
  rm "$tmpfile4"
  rm "$tmpfile5"
  rm "$tmpfile6"
}


run_tests(){

  test_replace_uuid_in_cmdline

}


