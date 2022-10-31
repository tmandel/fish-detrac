from csv import reader
from math import sqrt

"""
PR-MOTA score equation:
omega = (1/2)*sum(psi(pi,ri)*delta s)

(summing for i in C, where C is the PR curve)
(psi(p,r) is the MOTA value corresponding to the precision and recall on the PR curve)
The scores of other seven metrics, e.g., PR-MOTP and PR-IDS,
are similarly computed
"""

def calcDeltaS(p1, p2, r1, r2): #calculate change along the PR curve(delta s)
	deltaP = p2-p1
	deltaR = r2-r1
	deltaS = sqrt(deltaP**2 + deltaR**2)#Calculation of Euclidean distance
	return deltaS
	

def getMaxRow(motList):
	labels = ['Rcll', 'Prcn', 'FAR|','MT', 'PT', 'ML|', \
	'FP', 'FN', 'IDs', 'FM|', 'MOTA', 'MOTP', 'MOTAL']
	maxRow =motList[0]
	for row in motList:
		if(row[10]>maxRow[10]):
			maxRow = row
	print('results from max MOTA row')
	for k in range(len(labels)):
		print("{0}: {1}".format(labels[k],maxRow[k]))
	print()
	
def precisionRecallResults(detPRFile='R-CNN_detection_PR.txt', motResultFile='GOG_R-CNN_DETRAC-MOT_results.txt'):
	"""
	Args:
		File path of PR curve coordinates
		File path of mot results, representing Prcn, Rcll, MOTA, MOTP, etc...
	Returns:
		Prints PR-scores for thirteen metrics:
		1 R,2 P,3 FAR, 4 MT,5 PT,6 ML,7 FP,
		8 FN,9 IDs,10 FM,11 MOTA,12 MOTP,13 MOTAL
	"""
	
	prList = []
	with open(detPRFile) as f:#read PR coordinates, store as list of tuples
		csv_reader = reader(f, delimiter=' ')
		for row in csv_reader:
			precision = float(row[1])
			recall = float(row[0])
			prList.append((precision, recall))#append tuple

	motList = []
	with open(motResultFile) as f2:#read mot results, store as list of lists(2d array)
		csv_reader_2 = reader(f2)
		motResultData = list(csv_reader_2)
		for row in motResultData:
			motList.append(row) #append list
			
	"""
	Below are the column labels which correspond to the 
	mot results in motResultData:
	0 Thresh,1 R,2 P,3 FAR, 4 MT,5 PT,6 ML,7 FP,
	8 FN,9 IDs,10 FM,11 MOTA,12 MOTP,13 MOTAL
	"""
	#same labels as above, ommitting threshold column
	labels = ['PR-Rcll', 'PR-Prcn', 'PR-FAR|','PR-MT', 'PR-PT', 'PR-ML|', \
	'PR-FP', 'PR-FN', 'PR-IDs', 'PR-FM|', 'PR-MOTA', 'PR-MOTP', 'PR-MOTAL']
	
	getMaxRow(motList)
	
	for k in range(len(labels)):
		psiValues = []
		for row in motList:#list of scores for single result column(eg MOTA) over all thresholds
			psiValues.append(float(row[k+1]))#start at k+1 to ignore threshold values
		#left hand riemann sum
		lomega=0.0
		for i in range(len(psiValues)-2):#ignore last row, last row represents the results we are attempting to replicate
			p1, r1 = prList[i]
			p2, r2 = prList[i+1]
			lomega+=psiValues[i]*calcDeltaS(p1,p2,r1,r2)#See equation(line 6)
		lomega/=2
		#right hand riemann sum
		romega=0.0
		for i in range(len(psiValues)-2):#ignore last row, last row represents the results we are attempting to replicate
			p1, r1 = prList[i]
			p2, r2 = prList[i+1]
			romega+=psiValues[i+1]*calcDeltaS(p1,p2,r1,r2)#See equation(line 6)
		romega/=2
		#calculate trapezoid(average of left and right riemann sums)
		momega = (lomega+romega)/2
		print("{0}: {1:.4f}".format(labels[k],momega))
		

precisionRecallResults()
