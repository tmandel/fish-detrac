'''
Created on Nov 10, 2015

@author: jonas
'''
import time
import datetime

class Stopwatch(object):
    '''
    classdocs
    '''


    def __init__(self, print_time=True):
        '''
        Constructor
        '''
        self.__start = 0.0
        self.__stop = 0.0
        self.__time = 0.0
        self.print_time = print_time
    
    def start(self):
        self.__start = time.clock()
    
    def stop(self, s="Stopwatch"):
        self.__stop = time.clock()
        self.__time = self.__stop - self.__start
        str_out = datetime.timedelta(seconds=self.__time)
        if self.print_time:
            print(("{}: {}".format(s, str_out)))
        return str_out
        
        
    