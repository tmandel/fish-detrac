import scipy.io
import sys
import numpy as np

def upgradeOldMat(matFile):
    mat = scipy.io.loadmat(matFile)
    i = 0
    x = mat['gtInfo']['X'][0][0]
    y = mat['gtInfo']['Y'][0][0]
    w = mat['gtInfo']['W'][0][0]
    h = mat['gtInfo']['H'][0][0]
    #i = frame
    #j = track
    for i in range(len(x)):
        for j in range(len(x[i])):
            x[i][j] = x[i][j] + (w[i][j]/2)
            y[i][j] = y[i][j] + h[i][j]
    scipy.io.savemat(matFile, mat)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: upgradeOldMat.py matFile.mat")

    matFile = sys.argv[1]
    upgradeOldMat(matFile)
