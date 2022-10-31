function trackDuringOcclusion = getAnnotationStyle(seqName)
  %This script assumes that videos involving cars or pedestrians begin with 'MVI'.
  %This will need to be expanded in order to handle datasets other than DETRAC and 
  %our fish dataset.
  
  
  if (strcmp(substr(seqName, 1, 3), "MVI"))
    trackDuringOcclusion = false;
  else 
    trackDuringOcclusion = true;
  end
  
endfunction
