import os
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image as img
from tensorflow.keras.preprocessing.image import img_to_array
from keras import backend as k
import numpy as np
import tensorflow as tf
from PIL import Image, ImageOps
from tensorflow.keras.applications.resnet50 import ResNet50, decode_predictions, preprocess_input
from tensorflow.keras.initializers import glorot_uniform
from datetime import datetime
import io
from flask import Flask, Blueprint, request, render_template, jsonify
from modules.dataBase import collection as db

mod = Blueprint('backend', __name__, template_folder='templates', static_folder='./static')
UPLOAD_URL = 'http://192.168.1.14:5000/static/'
path_to_model = os.path.join('C:/Users/Dell/Downloads/Deploy-ML-model-master/FlaskBackend/modules/backed/keras_Model.h5')
np.set_printoptions(suppress=True)
path_to_lable=os.path.join('C:/Users/Dell/Downloads/Deploy-ML-model-master/FlaskBackend/modules/backed/labels.txt')
model = tf.keras.models.load_model(path_to_model,compile=False)
class_names = open(path_to_lable, "r").readlines()
@mod.route('/')
def home():
    return render_template('index.html')

@mod.route('/predict' ,methods=['POST'])
def predict():  
     if request.method == 'POST':
        # check if the post request has the file part
        if 'file' not in request.files:
           return "someting went wrong 1"
      
        user_file = request.files['file']
        temp = request.files['file']
        if user_file.filename == '':
            return "file name not found ..." 
       
        else:
            print("hhhhh")
            path = os.path.join('C:/Users/Dell/Downloads/Deploy-ML-model-master/FlaskBackend/modules/static/'+user_file.filename)
            user_file.save(path)
            class_name = identifyImage(path)
            return jsonify({"prediction": class_name[2:]})
          


def identifyImage(img_path):
    data = np.ndarray(shape=(1, 224, 224, 3), dtype=np.float32)
    image = Image.open(img_path).convert("RGB")
    size = (224, 224)
    image = ImageOps.fit(image, size, Image.Resampling.LANCZOS)
    image_array = np.asarray(image)
    normalized_image_array = (image_array.astype(np.float32) / 127.5) - 1
    data[0] = normalized_image_array
    prediction = model.predict(data)
    index = np.argmax(prediction)
    class_name = class_names[index]
    confidence_score = prediction[0][index]
    print("Class:", class_name[2:], end="")
    print("Confidence Score:", confidence_score)
    return  class_name



   




            
           
          


