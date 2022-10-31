#!/bin/bash 


for DIGIT in 0 1 2 3 4 5 6 7 8 9
do 
    rm -r trackers/KPD_ABL_PF_0.${DIGIT}
    cp -r trackers/KPD trackers/KPD_ABL_PF_0.${DIGIT}
    sed -i "s/ABLATE_PRE_FILTER = None/ABLATE_PRE_FILTER = 0.${DIGIT}/" trackers/KPD_ABL_PF_0.${DIGIT}/kpd_tracker.py
    sed -i "s/MIN_START_CONFIDENCE = 0.5/MIN_START_CONFIDENCE = 0.${DIGIT}/" trackers/KPD_ABL_PF_0.${DIGIT}/kpd_tracker.py
    sbatch slurm/run_reg.slurm KPD_ABL_PF_0.${DIGIT} fish-vids 0.5 
done



#sbatch slurm/run_reg.slurm KPD car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_PF car-validate 0.5 
#sbatch slurm/run_reg.slurm KPD_ABL_MED_SW car-validate 0.5 
#sbatch slurm/run_reg.slurm KPD_ABL_MED_REP car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_JOIN car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TF car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TNE car-validate 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TOS car-validate 0.5

#sbatch slurm/run_reg.slurm KPD trainlist-all 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_PF trainlist-all 0.5 
#sbatch slurm/run_reg.slurm KPD_ABL_MED trainlist-all 0.5 
#sbatch slurm/run_reg.slurm KPD_ABL_JOIN trainlist-all 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_NO_LL trainlist-all 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TLATE trainlist-all 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TEARLY trainlist-all 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TOFFS trainlist-all 0.5
#sbatch slurm/run_reg.slurm KPD_ABL_TONS trainlist-all 0.5

#time python experiment_wrapper.py KPD_ABL_PF all trainlist-all ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_MED_SW all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_MED_REP all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_JOIN all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_TF all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_TNE all trainlist-all  ~/my_octave/bin/octave-cli
#time python experiment_wrapper.py KPD_ABL_TNF all trainlist-all  ~/my_octave/bin/octave-cli
