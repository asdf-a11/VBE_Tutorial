#This program reduces the size of a image and then saves it as a
#list of bytes

from PIL import Image
import numpy as np
import math

IMAGE_FILE_PATH = "Lenna.png"
PIXLE_SIZE = 10
RES_X = 1280//PIXLE_SIZE
RES_Y = 1024//PIXLE_SIZE
print("RES_X, RES_Y",RES_X,RES_Y)
#rgb = 3 256 VGA default pallete is 1
BYTES_PER_PIXEL = 3

"""
This is a run length encoder, it might be usefull for large images. 
I find for smaller images it tends to increase the file size not reduce it though.
"""
#Calculates how similar two colours are
def CmpColour(c1,c2):
    if c2 == None:
        return 10000000
    t = sum([abs(int(v1)-int(v2))**2 for v1,v2 in zip(c1,c2)])
    return t
def RunLengthEncode(arr):
    prevValue = None
    repeatCounter = 0
    out = []
    for i in range(0,len(arr),BYTES_PER_PIXEL):
        value = [arr[j] for j in range(i,i+BYTES_PER_PIXEL)]
        #repeatCounter cant be greater than 255 becuse it is stored as a single byte
        if CmpColour(value, prevValue) < 100 and repeatCounter < 255:#30
            repeatCounter += 1 
        else:     
            if prevValue != None:       
                out.append(repeatCounter)
                out += list(prevValue)
            repeatCounter = 1#because value is value
        prevValue = value
    out += [repeatCounter] + list(value)
    return out
#Used for testing the run length encoder to make sure it works
def BackToImage(lst):
    uncompressed = []
    for i in range(0,len(lst),1+BYTES_PER_PIXEL):
        repeatValue = lst[i]
        value = [lst[j] for j in range(i+1,i+1+BYTES_PER_PIXEL)]
        uncompressed += list(value) * repeatValue
    print("bytes missing, ",RES_X*RES_Y*BYTES_PER_PIXEL-len(uncompressed))    
    ret = np.array(uncompressed, dtype=np.uint8).reshape((RES_Y,RES_X, BYTES_PER_PIXEL))
    img = Image.fromarray(ret)
    return img

img = Image.open(IMAGE_FILE_PATH)
img = img.resize((RES_X, RES_Y), resample=Image.NEAREST)
arr = np.array(img, dtype=np.uint8)
#This is a bit confusing, it flips the colour channel. So instead of RGB it is not BGR
#This is because when loading values in assembly it reads in little endian but it is stored big endiean.
#It is easier to flip here than in the bliter
arr = arr[:, :, ::-1]
#Converts to 1 dimensional list of data
arr = arr.flatten()


print("Number of bytes",len(arr), "Number of sectors to needed",math.ceil(len(arr)/512))
print("Remeber that you still need to store code and other data in memory so add 1 or two sectors" \
" so that you have enough memory")
with open("img.bin", "wb") as f:
    f.write(np.array(arr,dtype=np.uint8).tobytes())
