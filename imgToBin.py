#This program takes in a image, resizes it to fit the dimensions of VBE mode
#It can convert an image to use the default VGA colour pallete
#It then performs run length encoding
#Waring: The code in the bootloader can only load so many sectors so make sure images arn't too bit
#Also make sure to increase NUMBNER_OF_SECTORS_TO_LOAD for larger images

from PIL import Image
import numpy as np

IMAGE_FILE_PATH = "Lenna.png"
#Set the the resolution of the VBE mode you are using
ps = 10
RES_X = 1280//ps
RES_Y = 1024//ps
print(RES_X,RES_Y)
#rgb = 3 256 VGA default pallete is 1
BYTES_PER_PIXEL = 3
#
IS_DEFAULT_VGA_PALLETE = False

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
def BackToImage(lst):
    uncompressed = []
    for i in range(0,len(lst),1+BYTES_PER_PIXEL):
        repeatValue = lst[i]
        value = [lst[j] for j in range(i+1,i+1+BYTES_PER_PIXEL)]
        uncompressed += list(value) * repeatValue
    print("bytes missing, ",RES_X*RES_Y*BYTES_PER_PIXEL-len(uncompressed))
    #uncompressed += [0 for i in range(RES_X*RES_Y*BYTES_PER_PIXEL-len(uncompressed))]
    
    ret = np.array(uncompressed, dtype=np.uint8).reshape((RES_Y,RES_X, BYTES_PER_PIXEL))

    img = Image.fromarray(ret)
    return img

img = Image.open(IMAGE_FILE_PATH)

#img = img.resize((RES_X, RES_Y))
img = img.resize((RES_X, RES_Y), resample=Image.NEAREST)  # Downscale

#img = small.resize((RES_X, RES_Y), resample=Image.NEAREST)  # Upscale
#img.show()
arr = np.array(img, dtype=np.uint8)
arr = arr[:, :, ::-1]
arr = arr.flatten()


#a = len(arr)
#arr = RunLengthEncode(arr)
#BackToImage(arr).show()
#b = len(arr)
print(len(arr), len(arr)/512)
with open("img.bin", "wb") as f:
    f.write(np.array(arr,dtype=np.uint8).tobytes("C"))
#print("Done")
