import sys
import json
import matplotlib.pyplot as plt

def load_json(graph, name, usedMethods):
    methodNames = []
    for methods in graph[name]:
        methodNames.append(methods)
        print('Method: ' + methods['name'])
    method = input("Enter Method: ")
    if method not in methodNames:
        print("Invalid Method!")
        return
    if method in usedMethods:
        print("Method Is Already Added!")
        return
    usedMethods.append(method)
    for methods in graph[name]:
        if method is methods['name']:
            print("///////////" + method + " Method Information///////////")
            print("Average Precision Overall:", methods['AP'])
            print("Average Recall Overall:", methods['AR'])
            print("Average Precision at 0.5 Threshold:", methods['AP50'])
            print("Average Recall at 0.5 Threshold:", methods['AR50'])
            print("Mean Average Precision:", methods['mAP'])
            print("/////////////////////////////////////////////////\n")
            graphFormat = input("Enter Graph Format: ")
            try:
                plt.plot(methods['recalls'],methods['precisions'],graphFormat,label=methods['name'])
            except:
                print("Invalid Format! Using Default Format")
                plt.plot(methods['recalls'],methods['precisions'],label=methods['name'])

if __name__ == "__main__":
    
    
    #Is never used, just to reference all the methods
    fullLabelList = ["Retinanet","Mobilenetv2","ssdResnet","YOLOV4-608x608","TinyYOLOV4-416x416","TinyYOLOV4-608x608","Yolo-1024x1024", "Unity-MobileNet50" ,"Unity-Tiny-Yolov4-608x608","Unity-Resnet50","Yolov4Tiny-320x320","Unity-Tiny-Yolov4-320x320","Yolov3Tiny608", "Unity-Tiny-Yolov4-320x320-New","ConsoleMobileNet","Unity-MobileNet100","PythonTflie","Yolov4-320"]
    
    #Used to graph plots
    labelList = ["Retinanet","Yolov4-320","YOLOV4-608x608","Yolo-1024x1024"]
    
    #How the graph is displaying the methods with labelList respectfully
        #Make sure its the same length as LabelList
        #Take a look at this https://matplotlib.org/2.1.2/api/_as_gen/matplotlib.pyplot.plot.html
        #Leave Empty if you want to make it default
    formatList = ['k-.','r','g','b']

    #Name of the graph you want
    graphName = "Yolo Models"
    
    
    
    
    if len(sys.argv) < 2:
        print("Usage: loadGraphJson.py json/interactive")
        sys.exit(2)
    
    if sys.argv[1].strip().lower() == "json":
        for i in range(0,len(labelList)):
            with open(labelList[i] + '.json') as json_file:
                methods = json.load(json_file)
            for info in methods['method']:
                print("///////////" + labelList[i] + " Method Information///////////")
                print("Average Precision Overall:", info['AP'])
                print("Average Recall Overall:", info['AR'])
                print("Average Precision at 0.5 Threshold:", info['AP50'])
                print("Average Recall at 0.5 Threshold:", info['AR50'])
                print("Mean Average Precision:", info['mAP'])
                print("/////////////////////////////////////////////////\n")
                if len(formatList) == 0 :
                    plt.plot(info['recalls'],info['precisions'],label=info['name'])
                else:
                    plt.plot(info['recalls'],info['precisions'],formatList[i],label=info['name'])
        plt.xlabel('Recall')
        plt.ylabel('Precision')
        plt.title(graphName)
        plt.grid(True)
        plt.legend()
        plt.show()
    elif sys.argv[1].strip().lower() == "interactive": #Unstable! Dont use, just an idea I wanted to try
        with open('graph.json') as json_file:
            graph = json.load(json_file)  
        print("Add Graphs to plot!!")
        done = False;
        usedMethods=[]
        while not done:
            print("unity or python? d for done")
            name = input("Enter Name : ")
            if name[0] is 'u':
                load_json(graph,'unity',usedMethods)
            elif name[0] is 'p':
                load_json(graph,'python',usedMethods)
            elif name[0] is 'd':
                print("Done! Creating Graph...")
                done = True
            else:
                print("Invalid Name!")
                continue
        plt.xlabel('Recall')
        plt.ylabel('Precision')
        plt.title(graphName)
        plt.grid(True)
        plt.legend()
        plt.show()
    else:
        print("Usage: evalDetections.py json/interactive")
        sys.exit(2)