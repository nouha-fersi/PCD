import tensorflow as tf
import numpy as np
import io
from PIL import Image
from flask import Flask, request, jsonify
from tensorflow.keras.preprocessing.image import img_to_array, load_img
from tensorflow.keras.applications.resnet50 import preprocess_input

app = Flask(__name__)

# Load the Keras model
model = tf.keras.models.load_model('Xception_model.h5')

# Define the image size expected by the model
IMG_SIZE = (500, 250)

# Define the class labels for your model
labels = ['100frank', '10dt', '1dt', '200frank', '20dt','2dt','500frank','50dt','50frank','5dt']

def preprocess_image(image):
    # Resize the image to the required size
    img = image.resize(IMG_SIZE)
    
    # Convert the image to a NumPy array
    image_array = img_to_array(img)
    
    # Preprocess the image
    image_array = preprocess_input(image_array)
    
    return image_array

@app.route('/predict', methods=['POST'])
def predict():
    # Get the image file from the request
    file = request.files['image']
    
    # Read the image file
    image = Image.open(io.BytesIO(file.read()))

    # Preprocess the image
    preprocessed_image = preprocess_image(image)
    
    # Make a prediction using the model
    predictions = model.predict(np.array([preprocessed_image]))
    
    # Get the predicted class label
    predicted_index = np.argmax(predictions, axis=1)[0]
    predicted_label = labels[predicted_index]
    
    # Return the predicted class label as a JSON object
    response = {
        'class': predicted_label
    }
    
    return  jsonify (response)

if __name__ == "__main__":
    app.run(host='192.168.100.37', port=5000)
