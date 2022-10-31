'''
Created on Apr 5, 2016

@author: jj
'''
import pickle

class LabelTranslator(object):
    '''
    classdocs
    '''


    def __init__(self, label_file=None):
        """Init LabelTranslator 
        
        Load label_file to init label_to_id dictionary
        
        Args:
            label_file: Path to a pickle file.
        """
        self.label_to_id = dict()
        self.label_counter = 0
        self.label_file = label_file
        
        if label_file is not None:
            with open(label_file, 'rb') as pkl_file:
                self.label_to_id = pickle.load(pkl_file)
                try:
                    self.label_counter = max(self.label_to_id.values()) + 1
                except ValueError:
                    pass
    
    def set_label_id_pair(self, label, id):
        """Set an label, id pair in dictionary.
        
        Args:
            label: A string representing the label name.
            id: An int representing the label id.
        """
        self.label_to_id[label] = id
        
    def get_label(self, id):
        for label, id_i in self.label_to_id.items():
            if id_i == id:
                return label

    def get_id(self, label):
        if label in self.label_to_id:
            return self.label_to_id[label]
        else:
            self.label_to_id[label] = self.label_counter
            self.label_counter += 1
            return self.label_to_id[label]
        
    def save_label_file(self, label_file):
        """Pickle label_to_id
        
        Args:
            label_file: Filepath to store the label file.
        """
        with open(label_file, 'wb') as pkl_file:
            pickle.dump(self.label_to_id, pkl_file)
        self.label_file = label_file
        
    def __str__(self):
        str = "LabelTranslator:\n"
        str += "    labelfile:  {}\n".format(self.label_file)
        str += "    label_to_id:\n{}".format(self.label_to_id)
        return str
        
            