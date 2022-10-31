import scipy.io
import sys
import numpy as np
import showOnVideo
import showGT


def idScanner(bigList):
    ids = set()
    for frameList in bigList:
        for (box, score, id) in frameList:
            ids.add(id)
    return ids
    
def writeXML(bigList, filename):
    outF = open(filename, "w")
    header = '<?xml version="1.0" encoding="utf-8"?>\n'+\
    "<annotation>\n" + \
      "<folder>not available</folder>\n" +\
      "<filename>not available</filename>\n" +\
      "<source>\n" + \
        "<type>video</type>\n" + \
        "<sourceImage>vatic frames</sourceImage>\n" +\
        "<sourceAnnotation>vatic</sourceAnnotation>\n" + \
      "</source>\n"
    outF.write(header)
    ids = idScanner(bigList)
    
    for targetId in ids:
        objectString = ""
        minFrame = None
        maxFrame = None
        for f in range(len(bigList)):
               
            for (box, score, id) in bigList[f]:
                if id != targetId:
                    continue
                if minFrame is None or f < minFrame:
                    minFrame = f
                if maxFrame is None or f > maxFrame:
                    maxFrame = f
                (x,y,x2,y2) =box
                (x1,y1,x2,y2) = (str(x),str(y), str(x2), str(y2)) 
                
                objectString += "<polygon><t>" + str(f) + "</t><pt><x>" + x1 + "</x><y>" + y1 + "</y><l>1</l></pt><pt><x>" + x1 +"</x><y>" + y2 + "</y><l>1</l></pt><pt><x>"+x2+"</x><y>"+y2+"</y><l>1</l></pt><pt><x>" + x2+"</x><y>"+y1+"</y><l>1</l></pt></polygon>\n"
        objectHeader = "  <object>\n"+\
                "<name>Object_"+str(targetId)+"</name>\n" +\
                "<moving>true</moving>\n" + \
                "<action/>\n"+ \
                "<verified>0</verified>\n" + \
                "<id>undefined</id>\n" + \
                "<createdFrame>"+str(minFrame)+"</createdFrame>\n"+\
                "<startFrame>" + str(minFrame) + "</startFrame>\n" +\
                "<endFrame>"+str(maxFrame)+"</endFrame>\n";
                    
        outF.write(objectHeader + objectString + "</object>\n");
    outF.write("</annotation>\n")
    outF.close()
                   
                
      
      

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: matToVatic videoFile.mat")
        sys.exit(2)
    videoFile = sys.argv[1]
    outPrefix = videoFile[:-4]
    (h, w, x, y) = showGT.convertFile(outPrefix)
    bigList = showOnVideo.reformatOutput(x,y,h,w)
    writeXML(bigList, outPrefix+".xml")
    
    
