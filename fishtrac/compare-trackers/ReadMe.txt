The scripts in this folder will only work after
trackers have produced results in the 'results'
folder.

NOTE: Do NOT include suffix such as '.txt' when enterring cl
arguments for these scripts

Best practice: run all trackers in question
over a set of videos contained in a text file 
in evaluation/seqs/, run all trackers over
same set of thresholds (ideally all thresholds)

First: Run this once at end of experiment 
python benchmark_evaluation.py <sequence file prefix> <tracker/'all'> <thresh/'all'>
example -- { python benchmark_evaluation.py trainlist-full all all }

Second: Run this as many times as you want
python compare_trackers.py <sequence file prefix> <thresh/best> <"space separated tracker list" or 'all'> 
example -- { python compare_trackers.py trainlist-full best "KPD GOG VIOU DAN" }

Alternatively, you may choose to override the calculated best thresh produced
by benchmark eval and supply your own threshold to compare_trackers.
