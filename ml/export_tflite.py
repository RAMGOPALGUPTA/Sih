import argparse, tensorflow as tf
ap=argparse.ArgumentParser(); ap.add_argument('--model',required=True); ap.add_argument('--output',required=True); a=ap.parse_args()
m=tf.keras.models.load_model(a.model); c=tf.lite.TFLiteConverter.from_keras_model(m); c.optimizations=[tf.lite.Optimize.DEFAULT]; open(a.output,'wb').write(c.convert())
print(a.output)
