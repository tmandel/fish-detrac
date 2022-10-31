import csv
import matplotlib.image as mpimg

myFile = open('person_image/oidv6-train-annotations-bbox.csv', 'r')
reader = csv.DictReader(myFile)
myCSV = open('person_imag2/person_boxes.csv', 'w+')
writer = csv.writer(myCSV)
# writer.writerow(['imageID', 'x1', 'y1', 'x2', 'y2', 'class_name'])

imageName = set() 
skippedFiles = 0
for row in reader:
    if row['LabelName'] != '/m/01g317':
        continue
    imageID = row['ImageID'] 
    imageID = '/home/rebekkaw/research/bigdata/person_imag2/' + imageID + '.jpg'
    try:
        img = mpimg.imread(imageID)
    except FileNotFoundError:
        print("File not found", imageID)
        skippedFiles += 1
        continue
    except OSError:
        print("OSError", imageID)
        skippedFiles += 1
        continue
    print(imageID)
    if img.ndim == 4:
        (width, length, color, alpha) = img.shape  #numrows comes first, which is y
    if img.ndim == 3:
        (width, length, color) = img.shape
    if img.ndim == 2:
        (width, length) = img.shape
    x1 = int(float(row['XMin']) * length)
    y1 = int(float(row['YMin']) * width)
    x2 = int(float(row['XMax']) * length)
    y2 = int(float(row['YMax']) * width)
    class_name = 'person'
    #if imageID == '0000dd8e0cb25756':
    #    break

    imageName.add(imageID)
    if len(imageName) > 1800:
        imageName.remove(imageID)
        break

    writer.writerow([imageID, x1, y1, x2, y2, class_name])

print("Skipped:", skippedFiles)
print("Annotated:", len(imageName))
myFile.close()
myCSV.close()
