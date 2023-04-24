from flask import Flask, request, session, url_for, send_file ,render_template,redirect
from flask_pymongo import PyMongo
from gridfs import GridFS
from bson.objectid import ObjectId
from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
from flask_cors import CORS
from pymongo.database import Database
from bson.objectid import ObjectId

app = Flask(__name__)
app.config['MONGO_URI'] = 'mongodb+srv://nouhafersi:1234@cluster0.tgcshlz.mongodb.net/?retryWrites=true&w=majority'  # Update with your database name

mongo = PyMongo(app, uri='mongodb+srv://nouhafersi:1234@cluster0.tgcshlz.mongodb.net/?retryWrites=true&w=majority')

uri = "mongodb+srv://nouhafersi:1234@cluster0.tgcshlz.mongodb.net/?retryWrites=true&w=majority"

# Create a new client and connect to the server
client = MongoClient(uri, server_api=ServerApi('1'))

# Send a ping to confirm a successful connection
try:
    client.admin.command('ping')
    print("Pinged your deployment. You successfully connected to MongoDB!")
except Exception as e:
    print(e)

CORS(app)

app.config['TIMEOUT'] = 3600  # Set the timeout to 1 hour (in seconds)
@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        password = request.form.get('password')
        if password == '1234':
            return redirect('/admin')
        else:
            return render_template('login.html', message='Invalid password')
    else:
        return render_template('login.html')

@app.route('/admin', methods=['GET', 'POST'])
def admin():
    if request.method == 'POST':
        if 'modelh5' in request.files and 'label' in request.files:  # Update to check for both files
            modelh5 = request.files['modelh5']
            label = request.files['label']
            if modelh5.filename != '' and label.filename != '':  # Update to check for both filenames
                fs = GridFS(client.models)
                file_id_modelh5 = fs.put(modelh5, filename=modelh5.filename, chunk_size=1024*1024)
                file_id_label = fs.put(label, filename=label.filename, chunk_size=1024*1024)
                db = client.models
                db['models'].insert_one({'model_name': request.form.get('model_name'), 'modelh5_name': modelh5.filename, 'label_name': label.filename})  # Update to store both filenames
            return redirect(url_for('admin'))
        else:
            return 'nooo'
    else:
        db = client.models  # Access the Database instance from the mongo object
        fs = GridFS(db, collection='fs')  # Create a GridFS object with the Database instance and collection name
        files = db['models'].find()  # Find all documents in the 'models' collection
        model_names = [file['model_name'] for file in files]  # Extract the 'model_name' field from each document

        return render_template('admin.html', model_names=model_names)

@app.route('/file/<file_id>')
def file(file_id):
    db = client.models  # Access the Database instance from the mongo object
    fs = GridFS(db, collection='fs')  # Create a GridFS object with the Database instance and collection name
    file = fs.find_one({"_id": ObjectId(file_id)})  # Find the file in GridFS by ObjectId
    if file is not None:
        return

    
@app.route('/delete/<string:model_name>', methods=['POST'])
def delete_model(model_name):
    db = client.models

    # Find the document in the models collection by model_name
    model_doc = db['models'].find_one({'model_name': model_name})

    if model_doc:
        # Delete the document from the models collection
        db['models'].delete_one({'_id': model_doc['_id']})

        # Find the document in the fs.files collection by filename (modelh5_name)
        file_doc1 = db['fs.files'].find_one({'filename': model_doc['modelh5_name']})
        file_doc2 = db['fs.files'].find_one({'filename': model_doc['label_name']})
        if file_doc1 and file_doc2:
            # Delete the document from the fs.files collection
            db['fs.files'].delete_one({'_id': file_doc1['_id']})
            db['fs.files'].delete_one({'_id': file_doc2['_id']})

            # Find all documents in the fs.chunks collection by files_id
            chunk_docs1 = db['fs.chunks'].find({'files_id': file_doc1['_id']})
            chunk_docs2 = db['fs.chunks'].find({'files_id': file_doc2['_id']})
            for chunk_doc in chunk_docs1:
                # Delete the documents from the fs.chunks collection
                db['fs.chunks'].delete_one({'_id': chunk_doc['_id']})
            for chunk_doc in chunk_docs2:
                # Delete the documents from the fs.chunks collection
                db['fs.chunks'].delete_one({'_id': chunk_doc['_id']})

            return redirect(url_for('admin'))
        else:
            return {'error': 'Model file not found'}
    else:
        return {'error': 'Model not found'}


if __name__ == '__main__':
    app.debug = True
    app.run()