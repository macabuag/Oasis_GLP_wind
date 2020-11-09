#!/bin/bash
SCRIPT=$(readlink -f "$0") && cd $(dirname "$SCRIPT")

# --- Script Init ---

set -e
set -o pipefail
mkdir -p log
rm -R -f log/*


touch log/stderror.err
ktools_monitor.sh $$ & pid0=$!

exit_handler(){
   exit_code=$?
   kill -9 $pid0 2> /dev/null
   if [ "$exit_code" -gt 0 ]; then
       echo 'Ktools Run Error - exitcode='$exit_code
   else
       echo 'Run Completed'
   fi
   
   set +x
   group_pid=$(ps -p $$ -o pgid --no-headers)
   sess_pid=$(ps -p $$ -o sess --no-headers)
   script_pid=$$
   printf "Script PID:%d, GPID:%s, SPID:%d
" $script_pid $group_pid $sess_pid >> log/killout.txt

   ps f -g $sess_pid > log/subprocess_list
   PIDS_KILL=$(pgrep -a --pgroup $group_pid | awk -F: '$1>$script_pid' | grep -v celery | grep -v python | grep -v $group_pid | grep -v run_ktools)
   echo "$PIDS_KILL" >> log/killout.txt
   kill -9 $(echo "$PIDS_KILL" | awk 'BEGIN { FS = "[ \t\n]+" }{ print $1 }') 2>/dev/null
   exit $exit_code
}
trap exit_handler QUIT HUP INT KILL TERM ERR

check_complete(){
    set +e
    proc_list="eve getmodel gulcalc fmcalc summarycalc eltcalc aalcalc leccalc pltcalc"
    has_error=0
    for p in $proc_list; do
        started=$(find log -name "$p*.log" | wc -l)
        finished=$(find log -name "$p*.log" -exec grep -l "finish" {} + | wc -l)
        if [ "$finished" -lt "$started" ]; then
            echo "[ERROR] $p - $((started-finished)) processes lost"
            has_error=1
        elif [ "$started" -gt 0 ]; then
            echo "[OK] $p"
        fi
    done
    if [ "$has_error" -ne 0 ]; then
        false # raise non-zero exit code
    fi
}
# --- Setup run dirs ---

find output/* ! -name '*summary-info*' -exec rm -R -f {} +

rm -R -f fifo/*
rm -R -f work/*
mkdir work/kat/

mkdir work/gul_S1_summaryleccalc
mkdir work/gul_S1_summaryaalcalc
mkdir work/il_S1_summaryleccalc
mkdir work/il_S1_summaryaalcalc
mkdir work/ri_S1_summaryleccalc
mkdir work/ri_S1_summaryaalcalc

mkfifo fifo/gul_P1
mkfifo fifo/gul_P2
mkfifo fifo/gul_P3
mkfifo fifo/gul_P4
mkfifo fifo/gul_P5
mkfifo fifo/gul_P6
mkfifo fifo/gul_P7
mkfifo fifo/gul_P8
mkfifo fifo/gul_P9
mkfifo fifo/gul_P10
mkfifo fifo/gul_P11
mkfifo fifo/gul_P12
mkfifo fifo/gul_P13
mkfifo fifo/gul_P14
mkfifo fifo/gul_P15
mkfifo fifo/gul_P16
mkfifo fifo/gul_P17
mkfifo fifo/gul_P18
mkfifo fifo/gul_P19
mkfifo fifo/gul_P20

mkfifo fifo/gul_S1_summary_P1
mkfifo fifo/gul_S1_eltcalc_P1

mkfifo fifo/gul_S1_summary_P2
mkfifo fifo/gul_S1_eltcalc_P2

mkfifo fifo/gul_S1_summary_P3
mkfifo fifo/gul_S1_eltcalc_P3

mkfifo fifo/gul_S1_summary_P4
mkfifo fifo/gul_S1_eltcalc_P4

mkfifo fifo/gul_S1_summary_P5
mkfifo fifo/gul_S1_eltcalc_P5

mkfifo fifo/gul_S1_summary_P6
mkfifo fifo/gul_S1_eltcalc_P6

mkfifo fifo/gul_S1_summary_P7
mkfifo fifo/gul_S1_eltcalc_P7

mkfifo fifo/gul_S1_summary_P8
mkfifo fifo/gul_S1_eltcalc_P8

mkfifo fifo/gul_S1_summary_P9
mkfifo fifo/gul_S1_eltcalc_P9

mkfifo fifo/gul_S1_summary_P10
mkfifo fifo/gul_S1_eltcalc_P10

mkfifo fifo/gul_S1_summary_P11
mkfifo fifo/gul_S1_eltcalc_P11

mkfifo fifo/gul_S1_summary_P12
mkfifo fifo/gul_S1_eltcalc_P12

mkfifo fifo/gul_S1_summary_P13
mkfifo fifo/gul_S1_eltcalc_P13

mkfifo fifo/gul_S1_summary_P14
mkfifo fifo/gul_S1_eltcalc_P14

mkfifo fifo/gul_S1_summary_P15
mkfifo fifo/gul_S1_eltcalc_P15

mkfifo fifo/gul_S1_summary_P16
mkfifo fifo/gul_S1_eltcalc_P16

mkfifo fifo/gul_S1_summary_P17
mkfifo fifo/gul_S1_eltcalc_P17

mkfifo fifo/gul_S1_summary_P18
mkfifo fifo/gul_S1_eltcalc_P18

mkfifo fifo/gul_S1_summary_P19
mkfifo fifo/gul_S1_eltcalc_P19

mkfifo fifo/gul_S1_summary_P20
mkfifo fifo/gul_S1_eltcalc_P20

mkfifo fifo/il_P1
mkfifo fifo/il_P2
mkfifo fifo/il_P3
mkfifo fifo/il_P4
mkfifo fifo/il_P5
mkfifo fifo/il_P6
mkfifo fifo/il_P7
mkfifo fifo/il_P8
mkfifo fifo/il_P9
mkfifo fifo/il_P10
mkfifo fifo/il_P11
mkfifo fifo/il_P12
mkfifo fifo/il_P13
mkfifo fifo/il_P14
mkfifo fifo/il_P15
mkfifo fifo/il_P16
mkfifo fifo/il_P17
mkfifo fifo/il_P18
mkfifo fifo/il_P19
mkfifo fifo/il_P20

mkfifo fifo/il_S1_summary_P1
mkfifo fifo/il_S1_eltcalc_P1

mkfifo fifo/il_S1_summary_P2
mkfifo fifo/il_S1_eltcalc_P2

mkfifo fifo/il_S1_summary_P3
mkfifo fifo/il_S1_eltcalc_P3

mkfifo fifo/il_S1_summary_P4
mkfifo fifo/il_S1_eltcalc_P4

mkfifo fifo/il_S1_summary_P5
mkfifo fifo/il_S1_eltcalc_P5

mkfifo fifo/il_S1_summary_P6
mkfifo fifo/il_S1_eltcalc_P6

mkfifo fifo/il_S1_summary_P7
mkfifo fifo/il_S1_eltcalc_P7

mkfifo fifo/il_S1_summary_P8
mkfifo fifo/il_S1_eltcalc_P8

mkfifo fifo/il_S1_summary_P9
mkfifo fifo/il_S1_eltcalc_P9

mkfifo fifo/il_S1_summary_P10
mkfifo fifo/il_S1_eltcalc_P10

mkfifo fifo/il_S1_summary_P11
mkfifo fifo/il_S1_eltcalc_P11

mkfifo fifo/il_S1_summary_P12
mkfifo fifo/il_S1_eltcalc_P12

mkfifo fifo/il_S1_summary_P13
mkfifo fifo/il_S1_eltcalc_P13

mkfifo fifo/il_S1_summary_P14
mkfifo fifo/il_S1_eltcalc_P14

mkfifo fifo/il_S1_summary_P15
mkfifo fifo/il_S1_eltcalc_P15

mkfifo fifo/il_S1_summary_P16
mkfifo fifo/il_S1_eltcalc_P16

mkfifo fifo/il_S1_summary_P17
mkfifo fifo/il_S1_eltcalc_P17

mkfifo fifo/il_S1_summary_P18
mkfifo fifo/il_S1_eltcalc_P18

mkfifo fifo/il_S1_summary_P19
mkfifo fifo/il_S1_eltcalc_P19

mkfifo fifo/il_S1_summary_P20
mkfifo fifo/il_S1_eltcalc_P20

mkfifo fifo/ri_P1
mkfifo fifo/ri_P2
mkfifo fifo/ri_P3
mkfifo fifo/ri_P4
mkfifo fifo/ri_P5
mkfifo fifo/ri_P6
mkfifo fifo/ri_P7
mkfifo fifo/ri_P8
mkfifo fifo/ri_P9
mkfifo fifo/ri_P10
mkfifo fifo/ri_P11
mkfifo fifo/ri_P12
mkfifo fifo/ri_P13
mkfifo fifo/ri_P14
mkfifo fifo/ri_P15
mkfifo fifo/ri_P16
mkfifo fifo/ri_P17
mkfifo fifo/ri_P18
mkfifo fifo/ri_P19
mkfifo fifo/ri_P20

mkfifo fifo/ri_S1_summary_P1
mkfifo fifo/ri_S1_eltcalc_P1

mkfifo fifo/ri_S1_summary_P2
mkfifo fifo/ri_S1_eltcalc_P2

mkfifo fifo/ri_S1_summary_P3
mkfifo fifo/ri_S1_eltcalc_P3

mkfifo fifo/ri_S1_summary_P4
mkfifo fifo/ri_S1_eltcalc_P4

mkfifo fifo/ri_S1_summary_P5
mkfifo fifo/ri_S1_eltcalc_P5

mkfifo fifo/ri_S1_summary_P6
mkfifo fifo/ri_S1_eltcalc_P6

mkfifo fifo/ri_S1_summary_P7
mkfifo fifo/ri_S1_eltcalc_P7

mkfifo fifo/ri_S1_summary_P8
mkfifo fifo/ri_S1_eltcalc_P8

mkfifo fifo/ri_S1_summary_P9
mkfifo fifo/ri_S1_eltcalc_P9

mkfifo fifo/ri_S1_summary_P10
mkfifo fifo/ri_S1_eltcalc_P10

mkfifo fifo/ri_S1_summary_P11
mkfifo fifo/ri_S1_eltcalc_P11

mkfifo fifo/ri_S1_summary_P12
mkfifo fifo/ri_S1_eltcalc_P12

mkfifo fifo/ri_S1_summary_P13
mkfifo fifo/ri_S1_eltcalc_P13

mkfifo fifo/ri_S1_summary_P14
mkfifo fifo/ri_S1_eltcalc_P14

mkfifo fifo/ri_S1_summary_P15
mkfifo fifo/ri_S1_eltcalc_P15

mkfifo fifo/ri_S1_summary_P16
mkfifo fifo/ri_S1_eltcalc_P16

mkfifo fifo/ri_S1_summary_P17
mkfifo fifo/ri_S1_eltcalc_P17

mkfifo fifo/ri_S1_summary_P18
mkfifo fifo/ri_S1_eltcalc_P18

mkfifo fifo/ri_S1_summary_P19
mkfifo fifo/ri_S1_eltcalc_P19

mkfifo fifo/ri_S1_summary_P20
mkfifo fifo/ri_S1_eltcalc_P20



# --- Do reinsurance loss computes ---

eltcalc < fifo/ri_S1_eltcalc_P1 > work/kat/ri_S1_eltcalc_P1 & pid1=$!
eltcalc -s < fifo/ri_S1_eltcalc_P2 > work/kat/ri_S1_eltcalc_P2 & pid2=$!
eltcalc -s < fifo/ri_S1_eltcalc_P3 > work/kat/ri_S1_eltcalc_P3 & pid3=$!
eltcalc -s < fifo/ri_S1_eltcalc_P4 > work/kat/ri_S1_eltcalc_P4 & pid4=$!
eltcalc -s < fifo/ri_S1_eltcalc_P5 > work/kat/ri_S1_eltcalc_P5 & pid5=$!
eltcalc -s < fifo/ri_S1_eltcalc_P6 > work/kat/ri_S1_eltcalc_P6 & pid6=$!
eltcalc -s < fifo/ri_S1_eltcalc_P7 > work/kat/ri_S1_eltcalc_P7 & pid7=$!
eltcalc -s < fifo/ri_S1_eltcalc_P8 > work/kat/ri_S1_eltcalc_P8 & pid8=$!
eltcalc -s < fifo/ri_S1_eltcalc_P9 > work/kat/ri_S1_eltcalc_P9 & pid9=$!
eltcalc -s < fifo/ri_S1_eltcalc_P10 > work/kat/ri_S1_eltcalc_P10 & pid10=$!
eltcalc -s < fifo/ri_S1_eltcalc_P11 > work/kat/ri_S1_eltcalc_P11 & pid11=$!
eltcalc -s < fifo/ri_S1_eltcalc_P12 > work/kat/ri_S1_eltcalc_P12 & pid12=$!
eltcalc -s < fifo/ri_S1_eltcalc_P13 > work/kat/ri_S1_eltcalc_P13 & pid13=$!
eltcalc -s < fifo/ri_S1_eltcalc_P14 > work/kat/ri_S1_eltcalc_P14 & pid14=$!
eltcalc -s < fifo/ri_S1_eltcalc_P15 > work/kat/ri_S1_eltcalc_P15 & pid15=$!
eltcalc -s < fifo/ri_S1_eltcalc_P16 > work/kat/ri_S1_eltcalc_P16 & pid16=$!
eltcalc -s < fifo/ri_S1_eltcalc_P17 > work/kat/ri_S1_eltcalc_P17 & pid17=$!
eltcalc -s < fifo/ri_S1_eltcalc_P18 > work/kat/ri_S1_eltcalc_P18 & pid18=$!
eltcalc -s < fifo/ri_S1_eltcalc_P19 > work/kat/ri_S1_eltcalc_P19 & pid19=$!
eltcalc -s < fifo/ri_S1_eltcalc_P20 > work/kat/ri_S1_eltcalc_P20 & pid20=$!

tee < fifo/ri_S1_summary_P1 fifo/ri_S1_eltcalc_P1 work/ri_S1_summaryaalcalc/P1.bin work/ri_S1_summaryleccalc/P1.bin > /dev/null & pid21=$!
tee < fifo/ri_S1_summary_P2 fifo/ri_S1_eltcalc_P2 work/ri_S1_summaryaalcalc/P2.bin work/ri_S1_summaryleccalc/P2.bin > /dev/null & pid22=$!
tee < fifo/ri_S1_summary_P3 fifo/ri_S1_eltcalc_P3 work/ri_S1_summaryaalcalc/P3.bin work/ri_S1_summaryleccalc/P3.bin > /dev/null & pid23=$!
tee < fifo/ri_S1_summary_P4 fifo/ri_S1_eltcalc_P4 work/ri_S1_summaryaalcalc/P4.bin work/ri_S1_summaryleccalc/P4.bin > /dev/null & pid24=$!
tee < fifo/ri_S1_summary_P5 fifo/ri_S1_eltcalc_P5 work/ri_S1_summaryaalcalc/P5.bin work/ri_S1_summaryleccalc/P5.bin > /dev/null & pid25=$!
tee < fifo/ri_S1_summary_P6 fifo/ri_S1_eltcalc_P6 work/ri_S1_summaryaalcalc/P6.bin work/ri_S1_summaryleccalc/P6.bin > /dev/null & pid26=$!
tee < fifo/ri_S1_summary_P7 fifo/ri_S1_eltcalc_P7 work/ri_S1_summaryaalcalc/P7.bin work/ri_S1_summaryleccalc/P7.bin > /dev/null & pid27=$!
tee < fifo/ri_S1_summary_P8 fifo/ri_S1_eltcalc_P8 work/ri_S1_summaryaalcalc/P8.bin work/ri_S1_summaryleccalc/P8.bin > /dev/null & pid28=$!
tee < fifo/ri_S1_summary_P9 fifo/ri_S1_eltcalc_P9 work/ri_S1_summaryaalcalc/P9.bin work/ri_S1_summaryleccalc/P9.bin > /dev/null & pid29=$!
tee < fifo/ri_S1_summary_P10 fifo/ri_S1_eltcalc_P10 work/ri_S1_summaryaalcalc/P10.bin work/ri_S1_summaryleccalc/P10.bin > /dev/null & pid30=$!
tee < fifo/ri_S1_summary_P11 fifo/ri_S1_eltcalc_P11 work/ri_S1_summaryaalcalc/P11.bin work/ri_S1_summaryleccalc/P11.bin > /dev/null & pid31=$!
tee < fifo/ri_S1_summary_P12 fifo/ri_S1_eltcalc_P12 work/ri_S1_summaryaalcalc/P12.bin work/ri_S1_summaryleccalc/P12.bin > /dev/null & pid32=$!
tee < fifo/ri_S1_summary_P13 fifo/ri_S1_eltcalc_P13 work/ri_S1_summaryaalcalc/P13.bin work/ri_S1_summaryleccalc/P13.bin > /dev/null & pid33=$!
tee < fifo/ri_S1_summary_P14 fifo/ri_S1_eltcalc_P14 work/ri_S1_summaryaalcalc/P14.bin work/ri_S1_summaryleccalc/P14.bin > /dev/null & pid34=$!
tee < fifo/ri_S1_summary_P15 fifo/ri_S1_eltcalc_P15 work/ri_S1_summaryaalcalc/P15.bin work/ri_S1_summaryleccalc/P15.bin > /dev/null & pid35=$!
tee < fifo/ri_S1_summary_P16 fifo/ri_S1_eltcalc_P16 work/ri_S1_summaryaalcalc/P16.bin work/ri_S1_summaryleccalc/P16.bin > /dev/null & pid36=$!
tee < fifo/ri_S1_summary_P17 fifo/ri_S1_eltcalc_P17 work/ri_S1_summaryaalcalc/P17.bin work/ri_S1_summaryleccalc/P17.bin > /dev/null & pid37=$!
tee < fifo/ri_S1_summary_P18 fifo/ri_S1_eltcalc_P18 work/ri_S1_summaryaalcalc/P18.bin work/ri_S1_summaryleccalc/P18.bin > /dev/null & pid38=$!
tee < fifo/ri_S1_summary_P19 fifo/ri_S1_eltcalc_P19 work/ri_S1_summaryaalcalc/P19.bin work/ri_S1_summaryleccalc/P19.bin > /dev/null & pid39=$!
tee < fifo/ri_S1_summary_P20 fifo/ri_S1_eltcalc_P20 work/ri_S1_summaryaalcalc/P20.bin work/ri_S1_summaryleccalc/P20.bin > /dev/null & pid40=$!

( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P1 < fifo/ri_P1 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P2 < fifo/ri_P2 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P3 < fifo/ri_P3 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P4 < fifo/ri_P4 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P5 < fifo/ri_P5 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P6 < fifo/ri_P6 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P7 < fifo/ri_P7 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P8 < fifo/ri_P8 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P9 < fifo/ri_P9 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P10 < fifo/ri_P10 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P11 < fifo/ri_P11 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P12 < fifo/ri_P12 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P13 < fifo/ri_P13 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P14 < fifo/ri_P14 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P15 < fifo/ri_P15 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P16 < fifo/ri_P16 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P17 < fifo/ri_P17 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P18 < fifo/ri_P18 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P19 < fifo/ri_P19 ) 2>> log/stderror.err  &
( summarycalc -f -p RI_1 -1 fifo/ri_S1_summary_P20 < fifo/ri_P20 ) 2>> log/stderror.err  &

# --- Do insured loss computes ---

eltcalc < fifo/il_S1_eltcalc_P1 > work/kat/il_S1_eltcalc_P1 & pid41=$!
eltcalc -s < fifo/il_S1_eltcalc_P2 > work/kat/il_S1_eltcalc_P2 & pid42=$!
eltcalc -s < fifo/il_S1_eltcalc_P3 > work/kat/il_S1_eltcalc_P3 & pid43=$!
eltcalc -s < fifo/il_S1_eltcalc_P4 > work/kat/il_S1_eltcalc_P4 & pid44=$!
eltcalc -s < fifo/il_S1_eltcalc_P5 > work/kat/il_S1_eltcalc_P5 & pid45=$!
eltcalc -s < fifo/il_S1_eltcalc_P6 > work/kat/il_S1_eltcalc_P6 & pid46=$!
eltcalc -s < fifo/il_S1_eltcalc_P7 > work/kat/il_S1_eltcalc_P7 & pid47=$!
eltcalc -s < fifo/il_S1_eltcalc_P8 > work/kat/il_S1_eltcalc_P8 & pid48=$!
eltcalc -s < fifo/il_S1_eltcalc_P9 > work/kat/il_S1_eltcalc_P9 & pid49=$!
eltcalc -s < fifo/il_S1_eltcalc_P10 > work/kat/il_S1_eltcalc_P10 & pid50=$!
eltcalc -s < fifo/il_S1_eltcalc_P11 > work/kat/il_S1_eltcalc_P11 & pid51=$!
eltcalc -s < fifo/il_S1_eltcalc_P12 > work/kat/il_S1_eltcalc_P12 & pid52=$!
eltcalc -s < fifo/il_S1_eltcalc_P13 > work/kat/il_S1_eltcalc_P13 & pid53=$!
eltcalc -s < fifo/il_S1_eltcalc_P14 > work/kat/il_S1_eltcalc_P14 & pid54=$!
eltcalc -s < fifo/il_S1_eltcalc_P15 > work/kat/il_S1_eltcalc_P15 & pid55=$!
eltcalc -s < fifo/il_S1_eltcalc_P16 > work/kat/il_S1_eltcalc_P16 & pid56=$!
eltcalc -s < fifo/il_S1_eltcalc_P17 > work/kat/il_S1_eltcalc_P17 & pid57=$!
eltcalc -s < fifo/il_S1_eltcalc_P18 > work/kat/il_S1_eltcalc_P18 & pid58=$!
eltcalc -s < fifo/il_S1_eltcalc_P19 > work/kat/il_S1_eltcalc_P19 & pid59=$!
eltcalc -s < fifo/il_S1_eltcalc_P20 > work/kat/il_S1_eltcalc_P20 & pid60=$!

tee < fifo/il_S1_summary_P1 fifo/il_S1_eltcalc_P1 work/il_S1_summaryaalcalc/P1.bin work/il_S1_summaryleccalc/P1.bin > /dev/null & pid61=$!
tee < fifo/il_S1_summary_P2 fifo/il_S1_eltcalc_P2 work/il_S1_summaryaalcalc/P2.bin work/il_S1_summaryleccalc/P2.bin > /dev/null & pid62=$!
tee < fifo/il_S1_summary_P3 fifo/il_S1_eltcalc_P3 work/il_S1_summaryaalcalc/P3.bin work/il_S1_summaryleccalc/P3.bin > /dev/null & pid63=$!
tee < fifo/il_S1_summary_P4 fifo/il_S1_eltcalc_P4 work/il_S1_summaryaalcalc/P4.bin work/il_S1_summaryleccalc/P4.bin > /dev/null & pid64=$!
tee < fifo/il_S1_summary_P5 fifo/il_S1_eltcalc_P5 work/il_S1_summaryaalcalc/P5.bin work/il_S1_summaryleccalc/P5.bin > /dev/null & pid65=$!
tee < fifo/il_S1_summary_P6 fifo/il_S1_eltcalc_P6 work/il_S1_summaryaalcalc/P6.bin work/il_S1_summaryleccalc/P6.bin > /dev/null & pid66=$!
tee < fifo/il_S1_summary_P7 fifo/il_S1_eltcalc_P7 work/il_S1_summaryaalcalc/P7.bin work/il_S1_summaryleccalc/P7.bin > /dev/null & pid67=$!
tee < fifo/il_S1_summary_P8 fifo/il_S1_eltcalc_P8 work/il_S1_summaryaalcalc/P8.bin work/il_S1_summaryleccalc/P8.bin > /dev/null & pid68=$!
tee < fifo/il_S1_summary_P9 fifo/il_S1_eltcalc_P9 work/il_S1_summaryaalcalc/P9.bin work/il_S1_summaryleccalc/P9.bin > /dev/null & pid69=$!
tee < fifo/il_S1_summary_P10 fifo/il_S1_eltcalc_P10 work/il_S1_summaryaalcalc/P10.bin work/il_S1_summaryleccalc/P10.bin > /dev/null & pid70=$!
tee < fifo/il_S1_summary_P11 fifo/il_S1_eltcalc_P11 work/il_S1_summaryaalcalc/P11.bin work/il_S1_summaryleccalc/P11.bin > /dev/null & pid71=$!
tee < fifo/il_S1_summary_P12 fifo/il_S1_eltcalc_P12 work/il_S1_summaryaalcalc/P12.bin work/il_S1_summaryleccalc/P12.bin > /dev/null & pid72=$!
tee < fifo/il_S1_summary_P13 fifo/il_S1_eltcalc_P13 work/il_S1_summaryaalcalc/P13.bin work/il_S1_summaryleccalc/P13.bin > /dev/null & pid73=$!
tee < fifo/il_S1_summary_P14 fifo/il_S1_eltcalc_P14 work/il_S1_summaryaalcalc/P14.bin work/il_S1_summaryleccalc/P14.bin > /dev/null & pid74=$!
tee < fifo/il_S1_summary_P15 fifo/il_S1_eltcalc_P15 work/il_S1_summaryaalcalc/P15.bin work/il_S1_summaryleccalc/P15.bin > /dev/null & pid75=$!
tee < fifo/il_S1_summary_P16 fifo/il_S1_eltcalc_P16 work/il_S1_summaryaalcalc/P16.bin work/il_S1_summaryleccalc/P16.bin > /dev/null & pid76=$!
tee < fifo/il_S1_summary_P17 fifo/il_S1_eltcalc_P17 work/il_S1_summaryaalcalc/P17.bin work/il_S1_summaryleccalc/P17.bin > /dev/null & pid77=$!
tee < fifo/il_S1_summary_P18 fifo/il_S1_eltcalc_P18 work/il_S1_summaryaalcalc/P18.bin work/il_S1_summaryleccalc/P18.bin > /dev/null & pid78=$!
tee < fifo/il_S1_summary_P19 fifo/il_S1_eltcalc_P19 work/il_S1_summaryaalcalc/P19.bin work/il_S1_summaryleccalc/P19.bin > /dev/null & pid79=$!
tee < fifo/il_S1_summary_P20 fifo/il_S1_eltcalc_P20 work/il_S1_summaryaalcalc/P20.bin work/il_S1_summaryleccalc/P20.bin > /dev/null & pid80=$!

( summarycalc -f  -1 fifo/il_S1_summary_P1 < fifo/il_P1 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P2 < fifo/il_P2 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P3 < fifo/il_P3 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P4 < fifo/il_P4 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P5 < fifo/il_P5 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P6 < fifo/il_P6 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P7 < fifo/il_P7 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P8 < fifo/il_P8 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P9 < fifo/il_P9 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P10 < fifo/il_P10 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P11 < fifo/il_P11 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P12 < fifo/il_P12 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P13 < fifo/il_P13 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P14 < fifo/il_P14 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P15 < fifo/il_P15 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P16 < fifo/il_P16 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P17 < fifo/il_P17 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P18 < fifo/il_P18 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P19 < fifo/il_P19 ) 2>> log/stderror.err  &
( summarycalc -f  -1 fifo/il_S1_summary_P20 < fifo/il_P20 ) 2>> log/stderror.err  &

# --- Do ground up loss computes ---

eltcalc < fifo/gul_S1_eltcalc_P1 > work/kat/gul_S1_eltcalc_P1 & pid81=$!
eltcalc -s < fifo/gul_S1_eltcalc_P2 > work/kat/gul_S1_eltcalc_P2 & pid82=$!
eltcalc -s < fifo/gul_S1_eltcalc_P3 > work/kat/gul_S1_eltcalc_P3 & pid83=$!
eltcalc -s < fifo/gul_S1_eltcalc_P4 > work/kat/gul_S1_eltcalc_P4 & pid84=$!
eltcalc -s < fifo/gul_S1_eltcalc_P5 > work/kat/gul_S1_eltcalc_P5 & pid85=$!
eltcalc -s < fifo/gul_S1_eltcalc_P6 > work/kat/gul_S1_eltcalc_P6 & pid86=$!
eltcalc -s < fifo/gul_S1_eltcalc_P7 > work/kat/gul_S1_eltcalc_P7 & pid87=$!
eltcalc -s < fifo/gul_S1_eltcalc_P8 > work/kat/gul_S1_eltcalc_P8 & pid88=$!
eltcalc -s < fifo/gul_S1_eltcalc_P9 > work/kat/gul_S1_eltcalc_P9 & pid89=$!
eltcalc -s < fifo/gul_S1_eltcalc_P10 > work/kat/gul_S1_eltcalc_P10 & pid90=$!
eltcalc -s < fifo/gul_S1_eltcalc_P11 > work/kat/gul_S1_eltcalc_P11 & pid91=$!
eltcalc -s < fifo/gul_S1_eltcalc_P12 > work/kat/gul_S1_eltcalc_P12 & pid92=$!
eltcalc -s < fifo/gul_S1_eltcalc_P13 > work/kat/gul_S1_eltcalc_P13 & pid93=$!
eltcalc -s < fifo/gul_S1_eltcalc_P14 > work/kat/gul_S1_eltcalc_P14 & pid94=$!
eltcalc -s < fifo/gul_S1_eltcalc_P15 > work/kat/gul_S1_eltcalc_P15 & pid95=$!
eltcalc -s < fifo/gul_S1_eltcalc_P16 > work/kat/gul_S1_eltcalc_P16 & pid96=$!
eltcalc -s < fifo/gul_S1_eltcalc_P17 > work/kat/gul_S1_eltcalc_P17 & pid97=$!
eltcalc -s < fifo/gul_S1_eltcalc_P18 > work/kat/gul_S1_eltcalc_P18 & pid98=$!
eltcalc -s < fifo/gul_S1_eltcalc_P19 > work/kat/gul_S1_eltcalc_P19 & pid99=$!
eltcalc -s < fifo/gul_S1_eltcalc_P20 > work/kat/gul_S1_eltcalc_P20 & pid100=$!

tee < fifo/gul_S1_summary_P1 fifo/gul_S1_eltcalc_P1 work/gul_S1_summaryaalcalc/P1.bin work/gul_S1_summaryleccalc/P1.bin > /dev/null & pid101=$!
tee < fifo/gul_S1_summary_P2 fifo/gul_S1_eltcalc_P2 work/gul_S1_summaryaalcalc/P2.bin work/gul_S1_summaryleccalc/P2.bin > /dev/null & pid102=$!
tee < fifo/gul_S1_summary_P3 fifo/gul_S1_eltcalc_P3 work/gul_S1_summaryaalcalc/P3.bin work/gul_S1_summaryleccalc/P3.bin > /dev/null & pid103=$!
tee < fifo/gul_S1_summary_P4 fifo/gul_S1_eltcalc_P4 work/gul_S1_summaryaalcalc/P4.bin work/gul_S1_summaryleccalc/P4.bin > /dev/null & pid104=$!
tee < fifo/gul_S1_summary_P5 fifo/gul_S1_eltcalc_P5 work/gul_S1_summaryaalcalc/P5.bin work/gul_S1_summaryleccalc/P5.bin > /dev/null & pid105=$!
tee < fifo/gul_S1_summary_P6 fifo/gul_S1_eltcalc_P6 work/gul_S1_summaryaalcalc/P6.bin work/gul_S1_summaryleccalc/P6.bin > /dev/null & pid106=$!
tee < fifo/gul_S1_summary_P7 fifo/gul_S1_eltcalc_P7 work/gul_S1_summaryaalcalc/P7.bin work/gul_S1_summaryleccalc/P7.bin > /dev/null & pid107=$!
tee < fifo/gul_S1_summary_P8 fifo/gul_S1_eltcalc_P8 work/gul_S1_summaryaalcalc/P8.bin work/gul_S1_summaryleccalc/P8.bin > /dev/null & pid108=$!
tee < fifo/gul_S1_summary_P9 fifo/gul_S1_eltcalc_P9 work/gul_S1_summaryaalcalc/P9.bin work/gul_S1_summaryleccalc/P9.bin > /dev/null & pid109=$!
tee < fifo/gul_S1_summary_P10 fifo/gul_S1_eltcalc_P10 work/gul_S1_summaryaalcalc/P10.bin work/gul_S1_summaryleccalc/P10.bin > /dev/null & pid110=$!
tee < fifo/gul_S1_summary_P11 fifo/gul_S1_eltcalc_P11 work/gul_S1_summaryaalcalc/P11.bin work/gul_S1_summaryleccalc/P11.bin > /dev/null & pid111=$!
tee < fifo/gul_S1_summary_P12 fifo/gul_S1_eltcalc_P12 work/gul_S1_summaryaalcalc/P12.bin work/gul_S1_summaryleccalc/P12.bin > /dev/null & pid112=$!
tee < fifo/gul_S1_summary_P13 fifo/gul_S1_eltcalc_P13 work/gul_S1_summaryaalcalc/P13.bin work/gul_S1_summaryleccalc/P13.bin > /dev/null & pid113=$!
tee < fifo/gul_S1_summary_P14 fifo/gul_S1_eltcalc_P14 work/gul_S1_summaryaalcalc/P14.bin work/gul_S1_summaryleccalc/P14.bin > /dev/null & pid114=$!
tee < fifo/gul_S1_summary_P15 fifo/gul_S1_eltcalc_P15 work/gul_S1_summaryaalcalc/P15.bin work/gul_S1_summaryleccalc/P15.bin > /dev/null & pid115=$!
tee < fifo/gul_S1_summary_P16 fifo/gul_S1_eltcalc_P16 work/gul_S1_summaryaalcalc/P16.bin work/gul_S1_summaryleccalc/P16.bin > /dev/null & pid116=$!
tee < fifo/gul_S1_summary_P17 fifo/gul_S1_eltcalc_P17 work/gul_S1_summaryaalcalc/P17.bin work/gul_S1_summaryleccalc/P17.bin > /dev/null & pid117=$!
tee < fifo/gul_S1_summary_P18 fifo/gul_S1_eltcalc_P18 work/gul_S1_summaryaalcalc/P18.bin work/gul_S1_summaryleccalc/P18.bin > /dev/null & pid118=$!
tee < fifo/gul_S1_summary_P19 fifo/gul_S1_eltcalc_P19 work/gul_S1_summaryaalcalc/P19.bin work/gul_S1_summaryleccalc/P19.bin > /dev/null & pid119=$!
tee < fifo/gul_S1_summary_P20 fifo/gul_S1_eltcalc_P20 work/gul_S1_summaryaalcalc/P20.bin work/gul_S1_summaryleccalc/P20.bin > /dev/null & pid120=$!

( summarycalc -i  -1 fifo/gul_S1_summary_P1 < fifo/gul_P1 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P2 < fifo/gul_P2 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P3 < fifo/gul_P3 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P4 < fifo/gul_P4 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P5 < fifo/gul_P5 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P6 < fifo/gul_P6 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P7 < fifo/gul_P7 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P8 < fifo/gul_P8 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P9 < fifo/gul_P9 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P10 < fifo/gul_P10 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P11 < fifo/gul_P11 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P12 < fifo/gul_P12 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P13 < fifo/gul_P13 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P14 < fifo/gul_P14 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P15 < fifo/gul_P15 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P16 < fifo/gul_P16 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P17 < fifo/gul_P17 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P18 < fifo/gul_P18 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P19 < fifo/gul_P19 ) 2>> log/stderror.err  &
( summarycalc -i  -1 fifo/gul_S1_summary_P20 < fifo/gul_P20 ) 2>> log/stderror.err  &

( eve 1 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P1 | fmcalc -a2 | tee fifo/il_P1 | fmcalc -a3 -n -p RI_1 > fifo/ri_P1 ) 2>> log/stderror.err &
( eve 2 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P2 | fmcalc -a2 | tee fifo/il_P2 | fmcalc -a3 -n -p RI_1 > fifo/ri_P2 ) 2>> log/stderror.err &
( eve 3 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P3 | fmcalc -a2 | tee fifo/il_P3 | fmcalc -a3 -n -p RI_1 > fifo/ri_P3 ) 2>> log/stderror.err &
( eve 4 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P4 | fmcalc -a2 | tee fifo/il_P4 | fmcalc -a3 -n -p RI_1 > fifo/ri_P4 ) 2>> log/stderror.err &
( eve 5 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P5 | fmcalc -a2 | tee fifo/il_P5 | fmcalc -a3 -n -p RI_1 > fifo/ri_P5 ) 2>> log/stderror.err &
( eve 6 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P6 | fmcalc -a2 | tee fifo/il_P6 | fmcalc -a3 -n -p RI_1 > fifo/ri_P6 ) 2>> log/stderror.err &
( eve 7 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P7 | fmcalc -a2 | tee fifo/il_P7 | fmcalc -a3 -n -p RI_1 > fifo/ri_P7 ) 2>> log/stderror.err &
( eve 8 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P8 | fmcalc -a2 | tee fifo/il_P8 | fmcalc -a3 -n -p RI_1 > fifo/ri_P8 ) 2>> log/stderror.err &
( eve 9 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P9 | fmcalc -a2 | tee fifo/il_P9 | fmcalc -a3 -n -p RI_1 > fifo/ri_P9 ) 2>> log/stderror.err &
( eve 10 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P10 | fmcalc -a2 | tee fifo/il_P10 | fmcalc -a3 -n -p RI_1 > fifo/ri_P10 ) 2>> log/stderror.err &
( eve 11 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P11 | fmcalc -a2 | tee fifo/il_P11 | fmcalc -a3 -n -p RI_1 > fifo/ri_P11 ) 2>> log/stderror.err &
( eve 12 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P12 | fmcalc -a2 | tee fifo/il_P12 | fmcalc -a3 -n -p RI_1 > fifo/ri_P12 ) 2>> log/stderror.err &
( eve 13 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P13 | fmcalc -a2 | tee fifo/il_P13 | fmcalc -a3 -n -p RI_1 > fifo/ri_P13 ) 2>> log/stderror.err &
( eve 14 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P14 | fmcalc -a2 | tee fifo/il_P14 | fmcalc -a3 -n -p RI_1 > fifo/ri_P14 ) 2>> log/stderror.err &
( eve 15 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P15 | fmcalc -a2 | tee fifo/il_P15 | fmcalc -a3 -n -p RI_1 > fifo/ri_P15 ) 2>> log/stderror.err &
( eve 16 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P16 | fmcalc -a2 | tee fifo/il_P16 | fmcalc -a3 -n -p RI_1 > fifo/ri_P16 ) 2>> log/stderror.err &
( eve 17 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P17 | fmcalc -a2 | tee fifo/il_P17 | fmcalc -a3 -n -p RI_1 > fifo/ri_P17 ) 2>> log/stderror.err &
( eve 18 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P18 | fmcalc -a2 | tee fifo/il_P18 | fmcalc -a3 -n -p RI_1 > fifo/ri_P18 ) 2>> log/stderror.err &
( eve 19 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P19 | fmcalc -a2 | tee fifo/il_P19 | fmcalc -a3 -n -p RI_1 > fifo/ri_P19 ) 2>> log/stderror.err &
( eve 20 20 | getmodel | gulcalc -S10 -L0 -a1 -i - | tee fifo/gul_P20 | fmcalc -a2 | tee fifo/il_P20 | fmcalc -a3 -n -p RI_1 > fifo/ri_P20 ) 2>> log/stderror.err &

wait $pid1 $pid2 $pid3 $pid4 $pid5 $pid6 $pid7 $pid8 $pid9 $pid10 $pid11 $pid12 $pid13 $pid14 $pid15 $pid16 $pid17 $pid18 $pid19 $pid20 $pid21 $pid22 $pid23 $pid24 $pid25 $pid26 $pid27 $pid28 $pid29 $pid30 $pid31 $pid32 $pid33 $pid34 $pid35 $pid36 $pid37 $pid38 $pid39 $pid40 $pid41 $pid42 $pid43 $pid44 $pid45 $pid46 $pid47 $pid48 $pid49 $pid50 $pid51 $pid52 $pid53 $pid54 $pid55 $pid56 $pid57 $pid58 $pid59 $pid60 $pid61 $pid62 $pid63 $pid64 $pid65 $pid66 $pid67 $pid68 $pid69 $pid70 $pid71 $pid72 $pid73 $pid74 $pid75 $pid76 $pid77 $pid78 $pid79 $pid80 $pid81 $pid82 $pid83 $pid84 $pid85 $pid86 $pid87 $pid88 $pid89 $pid90 $pid91 $pid92 $pid93 $pid94 $pid95 $pid96 $pid97 $pid98 $pid99 $pid100 $pid101 $pid102 $pid103 $pid104 $pid105 $pid106 $pid107 $pid108 $pid109 $pid110 $pid111 $pid112 $pid113 $pid114 $pid115 $pid116 $pid117 $pid118 $pid119 $pid120


# --- Do reinsurance loss kats ---

kat work/kat/ri_S1_eltcalc_P1 work/kat/ri_S1_eltcalc_P2 work/kat/ri_S1_eltcalc_P3 work/kat/ri_S1_eltcalc_P4 work/kat/ri_S1_eltcalc_P5 work/kat/ri_S1_eltcalc_P6 work/kat/ri_S1_eltcalc_P7 work/kat/ri_S1_eltcalc_P8 work/kat/ri_S1_eltcalc_P9 work/kat/ri_S1_eltcalc_P10 work/kat/ri_S1_eltcalc_P11 work/kat/ri_S1_eltcalc_P12 work/kat/ri_S1_eltcalc_P13 work/kat/ri_S1_eltcalc_P14 work/kat/ri_S1_eltcalc_P15 work/kat/ri_S1_eltcalc_P16 work/kat/ri_S1_eltcalc_P17 work/kat/ri_S1_eltcalc_P18 work/kat/ri_S1_eltcalc_P19 work/kat/ri_S1_eltcalc_P20 > output/ri_S1_eltcalc.csv & kpid1=$!

# --- Do insured loss kats ---

kat work/kat/il_S1_eltcalc_P1 work/kat/il_S1_eltcalc_P2 work/kat/il_S1_eltcalc_P3 work/kat/il_S1_eltcalc_P4 work/kat/il_S1_eltcalc_P5 work/kat/il_S1_eltcalc_P6 work/kat/il_S1_eltcalc_P7 work/kat/il_S1_eltcalc_P8 work/kat/il_S1_eltcalc_P9 work/kat/il_S1_eltcalc_P10 work/kat/il_S1_eltcalc_P11 work/kat/il_S1_eltcalc_P12 work/kat/il_S1_eltcalc_P13 work/kat/il_S1_eltcalc_P14 work/kat/il_S1_eltcalc_P15 work/kat/il_S1_eltcalc_P16 work/kat/il_S1_eltcalc_P17 work/kat/il_S1_eltcalc_P18 work/kat/il_S1_eltcalc_P19 work/kat/il_S1_eltcalc_P20 > output/il_S1_eltcalc.csv & kpid2=$!

# --- Do ground up loss kats ---

kat work/kat/gul_S1_eltcalc_P1 work/kat/gul_S1_eltcalc_P2 work/kat/gul_S1_eltcalc_P3 work/kat/gul_S1_eltcalc_P4 work/kat/gul_S1_eltcalc_P5 work/kat/gul_S1_eltcalc_P6 work/kat/gul_S1_eltcalc_P7 work/kat/gul_S1_eltcalc_P8 work/kat/gul_S1_eltcalc_P9 work/kat/gul_S1_eltcalc_P10 work/kat/gul_S1_eltcalc_P11 work/kat/gul_S1_eltcalc_P12 work/kat/gul_S1_eltcalc_P13 work/kat/gul_S1_eltcalc_P14 work/kat/gul_S1_eltcalc_P15 work/kat/gul_S1_eltcalc_P16 work/kat/gul_S1_eltcalc_P17 work/kat/gul_S1_eltcalc_P18 work/kat/gul_S1_eltcalc_P19 work/kat/gul_S1_eltcalc_P20 > output/gul_S1_eltcalc.csv & kpid3=$!
wait $kpid1 $kpid2 $kpid3


aalcalc -Kri_S1_summaryaalcalc > output/ri_S1_aalcalc.csv & lpid1=$!
leccalc -r -Kri_S1_summaryleccalc -F output/ri_S1_leccalc_full_uncertainty_aep.csv -f output/ri_S1_leccalc_full_uncertainty_oep.csv & lpid2=$!
aalcalc -Kil_S1_summaryaalcalc > output/il_S1_aalcalc.csv & lpid3=$!
leccalc -r -Kil_S1_summaryleccalc -F output/il_S1_leccalc_full_uncertainty_aep.csv -f output/il_S1_leccalc_full_uncertainty_oep.csv & lpid4=$!
aalcalc -Kgul_S1_summaryaalcalc > output/gul_S1_aalcalc.csv & lpid5=$!
leccalc -r -Kgul_S1_summaryleccalc -F output/gul_S1_leccalc_full_uncertainty_aep.csv -f output/gul_S1_leccalc_full_uncertainty_oep.csv & lpid6=$!
wait $lpid1 $lpid2 $lpid3 $lpid4 $lpid5 $lpid6

rm -R -f work/*
rm -R -f fifo/*

check_complete
exit_handler
