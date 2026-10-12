#!/bin/sh
# Generic: regenerate s-oscons with the patched template, then build and run the time tests with
# the patched private runtime (and the unpatched system runtime as control).
cd /tmp/tt || exit 1
A=$(dirname "$(gcc -print-libgcc-file-name)"); T=$(gcc -dumpmachine)
echo "=== $T ($(uname -m)) ; runtime at $A"
rm -rf /tmp/os2 && mkdir -p /tmp/os2 && cd /tmp/os2 && tar xf /tmp/ada-top2.tar
gcc -E -C -DTARGET=\"$T\" -iquote . s-oscons-tmplt.c > s-oscons-tmplt.i 2> cpp.err; tail -2 cpp.err
gcc -S s-oscons-tmplt.i 2> cc.err; tail -3 cc.err
mkdir -p bt && cp xoscons.adb xutil.ads xutil.adb bt/ && (cd bt && gnatmake -q xoscons 2>&1 | tail -2) && ./bt/xoscons s-oscons
grep -nE "TIME64|SIZEOF_(tv_sec|tv_usec|tv_nsec|timespec)|OFFSET_tv_nsec" s-oscons.ads | cut -c1-70
cd /tmp/tt
for f in s-linux.ads g-sothco.ads; do cmp -s base2/$f $A/adainclude/$f && echo "$f baseline == installed" || echo "$f baseline DIFFERS from installed"; done
echo "=== CONTROL (system runtime) ==="
mkdir -p ctl && cp t64.adb t64c.adb ctl/ && cd ctl
gnatmake -q t64.adb -o t64_ctl 2>&1 | grep -v warning | head -3
gnatmake -q t64c.adb -o t64c_ctl 2>&1 | grep -v warning | head -3
timeout 60 ./t64_ctl | head -5; echo "rc=$?"; timeout 60 ./t64c_ctl; echo "rc=$?"
cd /tmp/tt
echo "=== PATCHED ==="
rm -rf rts2 && mkdir rts2 && cp -a $A/adainclude $A/adalib rts2/ && chmod -R u+w rts2
cmp -s base2/s-linux.ads $A/adainclude/s-linux.ads && cp stage/s-linux.ads rts2/adainclude/ || echo "(this arch uses another s-linux variant; left unchanged)"
cp stage/a-exetim.ads rts2/adainclude/a-exetim.ads
cp stage/s-osinte.ads stage/a-exetim.adb stage/s-osprim.adb stage/g-socthi.ads stage/g-sothco.ads stage/g-calend.ads rts2/adainclude/
cp /tmp/os2/s-oscons.ads rts2/adainclude/s-oscons.ads
(cd rts2/adainclude && touch a-exetim.ads s-linux.ads s-osinte.ads a-exetim.adb s-osprim.adb g-socthi.ads g-sothco.ads g-calend.ads s-oscons.ads)
cd rts2/adalib && for n in libgnat.a libgnarl.a libgnat_pic.a libgnarl_pic.a libgnat-15.so libgnarl-15.so; do ln -sf /usr/lib/$n $n; done; ln -sf /usr/lib/libgnat.a libgnat-15.a; ln -sf /usr/lib/libgnarl.a libgnarl-15.a; cd /tmp/tt
gcc -O2 -c stage/wrappers.c -o wrappers.o && echo "wrappers: $(nm wrappers.o | grep -c ' T __gnat_') symbols"
mkdir -p pat && cp t64.adb t64c.adb pat/ && cd pat
gnatmake --RTS=/tmp/tt/rts2 -a -f -gnatpg -gnatws -gnatyN -gnatn -O2 -fPIC t64.adb -o t64_pat -largs /tmp/tt/wrappers.o -static 2>&1 | grep -iE 'error|inconsist|undefined' | head -8
gnatmake --RTS=/tmp/tt/rts2 -a -gnatpg -gnatws -gnatyN -gnatn -O2 -fPIC t64c.adb -o t64c_pat -largs /tmp/tt/wrappers.o -static 2>&1 | grep -iE 'error|inconsist|undefined' | head -8
timeout 60 ./t64_pat; echo "rc=$?"; timeout 60 ./t64c_pat; echo "rc=$?"
echo "--- with Ada.Execution_Time enabled (Makefile.rtl change)"
cp /tmp/tt/t64b.adb . && gnatmake --RTS=/tmp/tt/rts2 -a -gnatpg -gnatws -gnatyN -gnatn -O2 -fPIC t64b.adb -o t64b_pat -largs /tmp/tt/wrappers.o -static 2>&1 | grep -iE 'error|inconsist|undefined|not supported' | head -5
timeout 60 ./t64b_pat; echo "rc=$?"
echo "uptime seconds: $(cut -d. -f1 /proc/uptime)  year: $(date +%Y)"
echo DONE
