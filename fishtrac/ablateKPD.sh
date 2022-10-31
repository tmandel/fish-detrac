#!/bin/bash 

rm -r trackers/KPD_ABL_PF
cp -r trackers/KPD trackers/KPD_ABL_PF
sed -i 's/ABLATE_PRE_FILTER = None/ABLATE_PRE_FILTER = 0.5/' trackers/KPD_ABL_PF/kpd_tracker.py

rm -r trackers/KPD_ABL_MED
cp -r trackers/KPD trackers/KPD_ABL_MED
sed -i 's/ABLATE_NO_MEDFLOW_SWITCH = False/ABLATE_NO_MEDFLOW_SWITCH = True/' trackers/KPD_ABL_MED/kpd_tracker.py
sed -i 's/ABLATE_NO_MEDFLOW_REPLACE = False/ABLATE_NO_MEDFLOW_REPLACE = True/' trackers/KPD_ABL_MED/kpd_tracker.py

#rm -r trackers/KPD_ABL_MED_REP
#cp -r trackers/KPD trackers/KPD_ABL_MED_REP
#sed -i 's/ABLATE_NO_MEDFLOW_REPLACE = False/ABLATE_NO_MEDFLOW_REPLACE = True/' trackers/KPD_ABL_MED_REP/kpd_tracker.py

rm -r trackers/KPD_ABL_JOIN
cp -r trackers/KPD trackers/KPD_ABL_JOIN
sed -i 's/ABLATE_NO_JOIN = False/ABLATE_NO_JOIN = True/' trackers/KPD_ABL_JOIN/kpd_tracker.py

rm -r trackers/KPD_ABL_NO_LL
cp -r trackers/KPD trackers/KPD_ABL_NO_LL
sed -i 's/ABLATE_NO_LONG_LARGE = False/ABLATE_NO_LONG_LARGE = True/' trackers/KPD_ABL_NO_LL/kpd_tracker.py

rm -r trackers/KPD_ABL_TLATE
cp -r trackers/KPD trackers/KPD_ABL_TLATE
sed -i 's/ABLATE_TRIM_LATE = False/ABLATE_TRIM_LATE = True/' trackers/KPD_ABL_TLATE/kpd_tracker.py

rm -r trackers/KPD_ABL_TEARLY
cp -r trackers/KPD trackers/KPD_ABL_TEARLY
sed -i 's/ABLATE_TRIM_EARLY = False/ABLATE_TRIM_EARLY = True/' trackers/KPD_ABL_TEARLY/kpd_tracker.py

rm -r trackers/KPD_ABL_TOFFS
cp -r trackers/KPD trackers/KPD_ABL_TOFFS
sed -i 's/ABLATE_TRIM_OFF_SCREEN = False/ABLATE_TRIM_OFF_SCREEN = True/' trackers/KPD_ABL_TOFFS/kpd_tracker.py

rm -r trackers/KPD_ABL_TONS
cp -r trackers/KPD trackers/KPD_ABL_TONS
sed -i 's/ABLATE_TRIM_ON_SCREEN = False/ABLATE_TRIM_ON_SCREEN = True/' trackers/KPD_ABL_TONS/kpd_tracker.py

#sbatch slurm/run_reg.slurm KPD car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_PF car-validate 0.5 
#sbatch slurm/run_reg.slurm KPD_ABL_MED_SW car-validate 0.5 
#sbatch slurm/run_reg.slurm KPD_ABL_MED_REP car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_JOIN car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TF car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TNE car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TOS car-validate 0.5

sbatch slurm/run_reg.slurm KPD trainlist-all 0.5
sbatch slurm/run_reg.slurm KPD_ABL_PF trainlist-all 0.5 
sbatch slurm/run_reg.slurm KPD_ABL_MED trainlist-all 0.5 
sbatch slurm/run_reg.slurm KPD_ABL_JOIN trainlist-all 0.5
sbatch slurm/run_reg.slurm KPD_ABL_NO_LL trainlist-all 0.5
sbatch slurm/run_reg.slurm KPD_ABL_TLATE trainlist-all 0.5
sbatch slurm/run_reg.slurm KPD_ABL_TEARLY trainlist-all 0.5
sbatch slurm/run_reg.slurm KPD_ABL_TOFFS trainlist-all 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TONS trainlist-all 0.5

#time python experiment_wrapper.py KPD_ABL_PF all trainlist-all ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_MED_SW all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_MED_REP all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_JOIN all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_TF all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_TNE all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_TNF all trainlist-all  ~/my_octave/bin/octave-cli
