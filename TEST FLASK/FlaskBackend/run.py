from modules import app
# 
# model = load_model("imagemodel.h5")
# print("model loading .... plaese wait this might take a while")
app.run(debug=False,host='192.168.1.14',port=5000)