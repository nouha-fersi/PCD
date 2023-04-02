import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing.image import img_to_array, load_img
from tensorflow.keras.applications.resnet50 import preprocess_input

# Load the Keras model
model = tf.keras.models.load_model('Xception_model.h5')

# Define the image size expected by the model
IMG_SIZE = (250, 500)

# Define the class labels for your model
labels = ['10', '20', 'class3', 'class4', 'class5']

# Load an example image and preprocess it
image = load_img('50dt.jpg', target_size=IMG_SIZE)
image_array = img_to_array(image)
preprocessed_image = preprocess_input(image_array)

# Make a prediction using the model
predictions = model.predict(np.array([preprocessed_image]))

# Get the predicted class label
predicted_index = np.argmax(predictions, axis=1)[0]
predicted_label = labels[predicted_index]

print("Predicted label:", predicted_label)
