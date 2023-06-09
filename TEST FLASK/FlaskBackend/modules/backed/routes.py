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
from pymongo.mongo_client import MongoClient
import base64
from pymongo.server_api import ServerApi
from gridfs import GridFS
import tempfile
def load_model_from_file():
   uri = "mongodb+srv://nouhafersi:1234@cluster0.tgcshlz.mongodb.net/?retryWrites=true&w=majority"
   client = MongoClient(uri, server_api=ServerApi('1'))
   db = client.models
   modelname = db['choosing_model'].find_one()['x']
   print (modelname)
   modelh5_name = db['models'].find_one({"model_name" : modelname }) ['modelh5_name']
   print (modelh5_name)
   label_name = db['models'].find_one({"model_name" : modelname }) ['label_name']
   print(label_name)
   fs = GridFS(db, collection='fs')
   label=fs.find_one({'filename': label_name})
   # save the file to a temporary file on your server
   with tempfile.NamedTemporaryFile(mode="wb", delete=False) as tmp:
      tmp.write(label.read())
# read the contents of the temporary file into a list
   with open(tmp.name, "r") as f:
      class_names = f.read().splitlines()
   print(class_names)
   fs = GridFS(db, collection='fs')
   file_doc = fs.find_one({'filename': modelh5_name})
   if file_doc is not None:
      file = fs.find_one({"filename": modelh5_name})
      if file is not None:
         model_data = file.read()
         with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp.write(model_data)
            tmp.flush()
            model = load_model(tmp.name)
         return [model, class_names]
      else:
         return f"File '{modelh5_name}' not found in MongoDB GridFS!"
   else:
      return f"File '{modelh5_name}' not found in MongoDB GridFS!"  

mod = Blueprint('backend', __name__, template_folder='templates', static_folder='./static')
UPLOAD_URL = 'http://192.168.1.12:5000/static/'
#path_to_model = os.path.join('C:/Users/Dell/Desktop/PCD/TEST FLASK/FlaskBackend/modules/backed/mobilenet_model.h5')
np.set_printoptions(suppress=True)
path_to_lable=os.path.join('C:/Users/Dell/Desktop/PCD/TEST FLASK/FlaskBackend/modules/backed/labels.txt')
#model = tf.keras.models.load_model(path_to_model,compile=False)
model=load_model_from_file()[0]
class_names  = load_model_from_file()[1]


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
            path = os.path.join('C:/Users/Dell/Desktop/PCD/TEST FLASK/FlaskBackend/modules/static'+user_file.filename)
            user_file.save(path)
            class_name = identifyImage(path)

            # Connect to MongoDB Atlas
            uri = "mongodb+srv://new:new20246653@cluster0.jfnbnlt.mongodb.net/?retryWrites=true&w=majority"
            client = MongoClient(uri)
            db = client['images']
            #test connection
            try:
               client.admin.command('ping')
               print("Pinged your deployment. You successfully connected to MongoDB!")

            except Exception as e:
               print(e)
 
            # Create a new collection for the predicted class if it doesn't exist
            if db.get_collection(class_name) is None:                        
            # Insert the image into the corresponding collection
               collection = db.create_collection(class_name)
            else:
            # Use the existing collection for the predicted class
              collection = db.get_collection(class_name)
            with open(path, 'rb') as f:
                image_bytes = f.read()

            # Convert the image to a base64 string
            image_base64 = base64.b64encode(image_bytes).decode('utf-8')

            # Store the image string in MongoDB
            collection.insert_one({'image': image_base64})
            
            return jsonify({"prediction": class_name[2:]})
         
        


def identifyImage(img_path):
    data = np.ndarray(shape=(1, 250, 500, 3), dtype=np.float32)
    image = Image.open(img_path).convert("RGB")
    size = (500, 250)
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




   




            
           
          


