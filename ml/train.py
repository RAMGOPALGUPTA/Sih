import argparse, json
from pathlib import Path
import numpy as np
from PIL import Image
from sklearn.model_selection import train_test_split
import tensorflow as tf

LABELS=['negative','positive','inconclusive']; SIZE=(224,224)
def load(data):
 x=[]; y=[]
 for i,label in enumerate(LABELS):
  for p in sorted((Path(data)/label).glob('*')):
   try: x.append(np.asarray(Image.open(p).convert('RGB').resize(SIZE),dtype=np.float32)/255.0); y.append(i)
   except Exception: pass
 if not x: raise SystemExit('No training images found')
 return np.array(x),tf.keras.utils.to_categorical(y,3)
def main():
 ap=argparse.ArgumentParser(); ap.add_argument('--data',default='dataset/raw'); ap.add_argument('--output',default='artifacts'); a=ap.parse_args(); Path(a.output).mkdir(exist_ok=True)
 x,y=load(a.data); xt,xv,yt,yv=train_test_split(x,y,test_size=.2,random_state=42,stratify=np.argmax(y,1))
 m=tf.keras.Sequential([tf.keras.layers.Input((*SIZE,3)),tf.keras.layers.Conv2D(16,3,activation='relu'),tf.keras.layers.MaxPooling2D(),tf.keras.layers.Conv2D(32,3,activation='relu'),tf.keras.layers.MaxPooling2D(),tf.keras.layers.Conv2D(64,3,activation='relu'),tf.keras.layers.GlobalAveragePooling2D(),tf.keras.layers.Dense(32,activation='relu'),tf.keras.layers.Dropout(.25),tf.keras.layers.Dense(3,activation='softmax')])
 m.compile('adam','categorical_crossentropy',metrics=['accuracy']); h=m.fit(xt,yt,validation_data=(xv,yv),epochs=30,batch_size=32,callbacks=[tf.keras.callbacks.EarlyStopping(patience=5,restore_best_weights=True)],verbose=2)
 m.save(Path(a.output)/'model.keras'); json.dump({'labels':LABELS,'image_size':SIZE,'validation_accuracy':float(max(h.history['val_accuracy']))},open(Path(a.output)/'metrics.json','w'),indent=2)
if __name__=='__main__': main()
